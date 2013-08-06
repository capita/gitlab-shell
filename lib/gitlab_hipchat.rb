require 'hipchat'

class GitlabHipchat
  def initialize(token, room_name)
    @token = token
    @room_name = room_name
    @username = 'Gitlab'
  end

  def notify_change(repo_name, branch_name, old_rev, new_rev)
    if old_rev.include?('000000000')
      # Branch is being removed
      send_to_room "#{repo_name} remote branch #{branch} has been deleted", 'red'
    else
      # Branch is being created
      if old_rev.include?('000000000')
        send_to_room "New branch on #{repo_name}: #{branch_name}", 'green'
        revs = "#{new_rev} -n 1" # just fetch the latest ref
      else
        revs = "#{old_rev}..#{new_rev}"
      end

      log = `git log #{revs} --pretty=format:'%an committed to _REPONAME_ %h%d %ar: %s'`
      log.split("\n").reverse.each do |line|
        send_to_room line.gsub('_REPONAME_', repo_name)
      end
    end
  end

  private

  def get_client(token)
    @client ||= HipChat::Client.new(token)
  end

  def get_room(client, room_name)
    @room ||= client.rooms.find { |r| r.name =~ /#{room_name}/i }
  end

  def send_to_room(message, color=nil)
    get_client(@token).get_room(@room_name).send @username, message, color
  end
end