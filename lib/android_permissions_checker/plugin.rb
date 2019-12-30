module Danger
  # Check permissions between current permissions and APK generated on CI service.
  # If changed, show permissions which added or deleted.
  #
  # @example Running Android permissions checker with its basic configuration
  #
  #          android_permissions_checker.check(
  #            apk: '/path/to/generated_apk_by_CI',
  #            permission_list_file: /path/to/permissions.txt
  #          )
  #
  # @example Running Android permissions checker with specific report method
  #
  #          android_permissions_checker.report_method = 'fail'
  #          android_permissions_checker.check(
  #            apk: '/path/to/generated_apk_by_CI',
  #            permission_list_file: /path/to/permissions.txt
  #          )
  #
  # @see mataku/danger-android_permissions_checker
  # @tags android, permissions, apk

  class DangerAndroidPermissionsChecker < Plugin
    REPORT_METHODS = %i(message warn fail).freeze

    # *Optional*
    # Set report method
    #
    # @return [String, Symbol] error by default
    attr_accessor :report_method

    # Calls permissions check.
    # @return [void]
    def check(apk: nil, permission_list_file: nil)
      if apk.nil? || !File.exist?(apk)
        raise "Can't find apk: #{apk}"
      end

      if permission_list_file.nil? || !File.exist?(permission_list_file)
        raise "Can't find permission list file: #{permission_list_file}\n"
      end

      unless system 'which aapt > /dev/null 2>&1'
        raise "Can't find required command: aapt. Set PATH to Android Build-tools."
      end

      @report_method = (report_method || :warn).to_sym
      unless REPORT_METHODS.include?(report_method)
        raise "Unknown report method: #{report_method}"
      end

      generated_permissions = `aapt d permissions #{apk}`.split("\n")
      current_permissions = File.open(permission_list_file).readlines.map(&:chomp)

      deleted = current_permissions - generated_permissions
      added = generated_permissions - current_permissions
      message = ""

      if deleted.length > 0
        message += "### Deleted permissions\n"
        deleted.each do |v|
          message += "- #{v}\n"
        end
        message += "\n"
      end

      if added.length > 0
        message += "### Added Permissions\n"

        added.each do |v|
          message += "- #{v}\n"
        end
      end

      unless message.empty?
        markdown(message)
        send(report_method, "APK permissions changed, see below. Should update `#{permission_list_file}` if it is intended change.")
      end
    end
  end
end
