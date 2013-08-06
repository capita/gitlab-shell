require 'hipchat'

class GitlabHipchat
  def initialize(token, room_id)
    @token = token
    @room_id = room_id
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

  def get_room(room_id)
    @room ||= get_client(@token)[room_id]
  end

  def send_to_room(message, color=nil)
    get_room(@room_id).send @username, message, color
  end
end
