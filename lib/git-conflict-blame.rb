require 'git-conflict-blame/exceptions'
require 'rugged'
require 'colorize'
require 'open3'
require 'json'

# Git command that shows the blame on the lines that are in conflict. This should be ran
# after a "git merge" command has been ran and there are files that are in conflict.
class GitConflictBlame

  # @param json [Boolean] Whether or not to output in JSON format
  # @param pretty_json [Boolean] Whether or not to output in pretty JSON format
  def initialize( json: false, pretty_json: false )
    @json        = json
    @pretty_json = pretty_json
    @current_dir = Dir.pwd
    @repo = Rugged::Repository.discover( @current_dir )
  end

  # Main public method to run on the class
  #
  # @param options [Hash] Run options
  def self.run( options )
    new( options ).run!
  end

  # Actually performs the conflict blame
  def run!
    if conflicts?
      Dir.chdir( @repo.workdir )
      log "#{conflict_count} files are in conflict".red
      log "Parsing files to find out who is to blame..."
      data, total_conflicts = find_conflict_blames

      if total_conflicts == 0
        if conflict_count == 0
          log "All conflicts appear to be resolved".green
        else
          log "\nThere are #{conflict_count} files in conflict that cannot be blamed:".red
          remaining_conflicted_files = cmd( 'git diff --name-only --diff-filter=U' )
          log remaining_conflicted_files
          if @json
            data = {}
            remaining_conflicted_files.split( "\n" ).each do |file_name|
              data[file_name] = 'conflict cannot be blamed'
            end
          end
        end
      else
        log "#{total_conflicts} total conflicts found!\n".red
      end

      if @json
        json_data = {
          exception:   false,
          file_count:  conflict_count,
          total_count: total_conflicts,
          data:        data
        }
        output_json( json_data )
      else
        display_results( data )
      end
    else
      log 'No conflicts found'.green
    end
  rescue GitError => e
    log_error( e )
    exit 1
  rescue CmdError => e
    message =  "This is probably a bug. Please log it here:\n"
    message << "https://github.com/eterry1388/git-conflict-blame/issues"
    log_error( e, message: message )
    exit 1
  rescue Exception => e
    message =  "#{e.backtrace.join( "\n" )}\n"
    message << "Unhandled exception! This is probably a bug. Please log it here:\n"
    message << "https://github.com/eterry1388/git-conflict-blame/issues"
    log_error( e, message: message )
    exit 1
  ensure
    Dir.chdir( @current_dir )
  end

  private

  # Outputs a message
  #
  # @note This will not output anything if @json is set!
  # @param message [String]
  def log( message = '' )
    return if @json
    puts message
  end

  # Outputs an error message
  #
  # @param e [Exception]
  # @param message [String] Error message
  def log_error( e, message: '' )
    if @json
      message = "#{e.message}\n#{message}" 
      error_hash = {
        exception: true,
        type:      e.class,
        message:   message
      }
      output_json( error_hash )
    else
      puts "#{e.class}: #{e.message}"
      puts message if message
    end
  end

  # Run a command
  #
  # @param command [String] the command to run
  # @raise [CmdError] if command is not successful
  # @return [String] the output (stdout) of running the command
  def cmd( command )
    stdout, stderr, status = Open3.capture3( command )
    unless status.success?
      raise CmdError, "Command: '#{command}', Stdout: '#{stdout}', Stderr: '#{stderr}'"
    end
    stdout
  rescue Errno::ENOENT => e
    raise CmdError, "Command: '#{command}', Error: '#{e}'"
  end

  # Figures out if there are any conflicts in the git repo
  #
  # @return [Boolean]
  def conflicts?
    @repo.index.conflicts?
  end

  # Gets all the filenames that are in conflict
  #
  # @return [Array<String>]
  def conflicts
    @conflicts ||= @repo.index.conflicts.map do |conflict|
      ours = conflict[:ours]
      ours[:path] if ours
    end.compact
  end

  # Gets the total number of files that are in conflict
  #
  # @return [Integer] Number of files in conflict
  def conflict_count
    @conflict_count ||= @repo.index.conflicts.count
  end

  # Runs the "git blame" command
  #
  # @param filename [String]
  # @return [String] Raw results of the "git blame" command
  def raw_blame( filename )
    cmd( "git blame --show-email -c --date short #{filename}" )
  end

  # Parses through the conflicted files and finds the blame on each line
  #
  # @return [Array] [data_hash, conflict_count]
  def find_conflict_blames
    data = {}
    total_conflicts = 0

    conflicts.each do |conflict|
      begin
        raw = raw_blame( conflict )
        start_indexes = []
        end_indexes = []
        lines = raw.split( "\n" )
        lines.each do |line|
          start_indexes << lines.index( line ) if line.include?( '<<<<<<<' )
          end_indexes   << lines.index( line ) if line.include?( '>>>>>>>' )
        end

        index = 0
        all_line_sets = []
        start_indexes.count.times do
          start_index = start_indexes[index]
          end_index = end_indexes[index]
          line_set = lines[start_index..end_index]
          all_line_sets << parse_lines( line_set )
          index += 1
        end
        total_conflicts += start_indexes.count
        data[conflict] = all_line_sets
      rescue ArgumentError
        # Do nothing
        # Caused by encoding issues like "invalid byte sequence in UTF-8"
      end
    end
    data.delete_if { |_, all_line_sets| all_line_sets.nil? || all_line_sets.empty? }

    [data, total_conflicts]
  end

  # Iterates through a line set and parses them
  #
  # @param lines [Array<String>]
  # @return [Array<Hash>]
  def parse_lines( lines )
    lines.map { |line| parse_line( line ) }
  end

  # Parses a line from the "git blame" command
  #
  # @param line [String]
  # @return [Hash]
  def parse_line( line )
    line_array = line.split( "\t" )
    commit_id = line_array[0]
    email     = line_array[1].delete( '(' ).delete( '<' ).delete( '>' )
    date      = line_array[2]
    raw_line  = line_array[3..999].join( "\t" )
    raw_line_array = raw_line.split( ')' )
    line_number  = raw_line_array[0].to_i
    line_content = raw_line_array[1..999].join( ')' )

    {
      commit_id:    commit_id,
      email:        email,
      date:         date,
      line_number:  line_number,
      line_content: line_content
    }
  end

  # Outputs a Hash in JSON format
  #
  # @param hash [Hash]
  def output_json( hash )
    if @pretty_json
      puts JSON.pretty_generate( hash )
    else
      puts hash.to_json
    end
  end

  # Outputs the results of {#find_conflict_blames} to the console
  #
  # @param data [Hash]
  def display_results( data )
    data.each do |filename, conflicts|
      log filename.green
      conflicts.each do |lines|
        lines.each do |line|
          git_info = [line[:commit_id], line[:email][0..30], line[:date]]
          formatted_git_info =  "\t%-10s %-30s %-13s" % git_info

          if line[:line_content].include?( '<<<<<<<' ) || line[:line_content].include?( '>>>>>>>' )
            line_color = :red
          elsif line[:line_content].include?( '=======' )
            line_color = :yellow
          else
            line_color = :light_blue
          end

          line_data = [formatted_git_info, line[:line_number].to_s.bold, line[:line_content].colorize( line_color )]
          log "%s [%-20s]  %-s" % line_data
        end
        log # New line
      end
    end
  end
end
