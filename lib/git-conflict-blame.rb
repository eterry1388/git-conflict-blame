require 'git-conflict-blame/exceptions'
require 'rugged'
require 'colorize'
require 'open3'
require 'json'

class GitConflictBlame

  def initialize( json: false, pretty_json: false )
    @json        = json
    @pretty_json = pretty_json
    @current_dir = Dir.pwd
    @repo = Rugged::Repository.discover( @current_dir )
    run!
  end

  def self.run( options )
    new( options )
  end

  def run!
    Dir.chdir( @repo.workdir )
    raise GitError, 'No conflicts found' unless conflicts?
    log "#{conflicts.count} conflicts found!".red
    log "Parsing files to find out who is to blame..."
    data = find_conflict_blames
    if @json
      json_data = {
        exception: false,
        count:     conflicts.count,
        data:      data
      }
      output_json( json_data )
    else
      display_results( data )
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

  def log( message = '' )
    return if @json
    puts message
  end

  def log_error( e, message: )
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

  # Run a command.
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

  def conflicts?
    @repo.index.conflicts?
  end

  def conflicts
    @conflicts ||= @repo.index.conflicts.map { |conflict| conflict[:ours][:path] }
  end

  def raw_blame( filename )
    cmd( "git blame --show-email -c --date short #{filename}" )
  end

  def find_conflict_blames
    data = {}
    conflicts.each do |conflict|
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
      data[conflict] = all_line_sets
    end
    data.delete_if { |_, all_line_sets| all_line_sets.nil? || all_line_sets.empty? }
    data
  end

  def parse_lines( lines )
    lines.map { |line| parse_line( line ) }
  end

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

  def output_json( hash )
    if @pretty_json
      puts JSON.pretty_generate( hash )
    else
      puts hash.to_json
    end
  end

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
