require 'rugged'
require 'colorize'
require 'open3'
require 'git-conflict-blame/exceptions'

class GitConflictBlame

  def self.run( argv )
    new( argv )
  end

  def initialize( argv )
    @argv = argv
    @repo = Rugged::Repository.discover( Dir.pwd )
    raise GitError, 'No conflicts found' unless conflicts?
    puts "#{conflicts.count} conflicts found!"
    data = find_conflict_blames
    display_results( data )
  rescue GitError => e
    puts "GitError: #{e.message}"
    exit 1
  rescue Exception => e
    puts 'Unhandled exception! This is probably a bug. Please log it here:'
    puts 'https://github.com/eterry1388/git-conflict-blame/issues'
    puts e
    exit 1
  end

  # Runs the command.
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
      all_lines = []
      start_indexes.count.times do
        start_index = start_indexes[index]
        end_index = end_indexes[index]
        all_lines << lines[start_index..end_index]
        index += 1
      end
      data[conflict] = all_lines
    end
    data.delete_if { |_, all_lines| all_lines.nil? || all_lines.empty? }
    data
  end

  def display_results( data )
    data.each do |filename, conflicts|
      puts filename.green
      conflicts.each do |lines|
        lines.each do |line|
          line_array = line.split( "\t" )

          commit_id = line_array[0]
          email     = line_array[1].delete( "(" )[0..30]
          date      = line_array[2]

          git_info = [commit_id, email, date]
          raw_line = line_array[3..999].join( "\t" )
          raw_line_array = raw_line.split( ")" )
          line_number = raw_line_array.first
          raw_line_string = raw_line_array[1..999].join( ")" )

          formatted_git_info =  "\t%-10s %-30s %-13s" % git_info
          if raw_line.include?( '<<<<<<<' ) || raw_line.include?( '>>>>>>>' )
            raw_line_string = raw_line_string.red
          elsif raw_line.include?( '=======' )
            raw_line_string = raw_line_string.yellow
          else
            raw_line_string = raw_line_string.light_blue
          end
          puts "%s [%-22s]  %-s" % [formatted_git_info, line_number.bold, raw_line_string]
          puts if raw_line.include?( '>>>>>>>' )
        end
      end
    end
  end
end
