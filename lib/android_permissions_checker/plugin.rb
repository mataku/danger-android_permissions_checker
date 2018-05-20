require 'fileutils'
require 'diffy'

module Danger
  class DangerAndroidPermissionsChecker < Plugin
    def check(apk_path: nil, permission_list_file_path: nil)
      tmp_file = '/tmp/permissions.txt'

      if apk_path.nil? || !File.exist?(apk_path)
        raise "Can\'t find apk: #{apk_path}"
      end

      if permission_list_file_path.nil? || !File.exist?(permission_list_file_path)
        raise "Can't find permission list file: #{permission_list_file_path}"
      end

      unless system 'which aapt > /dev/null 2>&1'
        raise 'Can\'t find required command: aapt. Set PATH to Android Build-tools.'
      end

      `aapt d permissions #{apk_path} | sort > #{tmp_file}`
      diff = `diff #{tmp_file} <(sort #{permission_list_file_path})`

      if diff
        warn("Permissions changed.\n```#{diff}```")
      end
    end
  end
end

