require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerAndroidPermissionsChecker do
    let(:dangerfile) { testing_dangerfile }
    let(:plugin) { dangerfile.android_permissions_checker }

    it "should be a plugin" do
      expect(Danger::DangerAndroidPermissionsChecker.new(nil)).to be_a Danger::Plugin
    end

    describe "#check" do

      let(:tmp_file) { '/tmp/permissions.txt' }
      let(:current_permission_file) { 'permissions.txt' }
      let(:apk) { '/tmp/app.apk' }
      let(:aapt_command) { "aapt d permissions #{apk}" }
      let(:generated_permissions) do
        "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\n"
      end

      let(:current_permission_list) do
        [
          "package: com.mataku.scrobscrob.dev\n",
          "uses-permission: name='android.permission.INTERNET'\n"
        ]
      end

      before do
        allow(current_permission_file).to receive(:nil?).and_return(false)
        allow(apk).to receive(:nil?).and_return(false)
        allow(File).to receive(:exist?).with(current_permission_file).and_return(true)
        allow(File).to receive(:exist?).with(apk).and_return(true)
        allow_any_instance_of(Kernel).to receive(:system).with('which aapt > /dev/null 2>&1').and_return(true)
        allow_any_instance_of(Kernel).to receive(:`).with(aapt_command).and_return(generated_permissions)
        allow(File).to receive_message_chain(:open, :readlines).with(current_permission_file).with(no_args).and_return(current_permission_list)
      end

      it do
        plugin.check(apk: apk, permission_list_file: current_permission_file)
        expect(dangerfile.status_report[:warnings].length).to eq(0)
      end

      context 'Permission added' do
        let(:generated_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\nuses-permission: name='com.mataku.INTERNET'\n"
        end

        it do
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:warnings].length).to eq(1)
          expect(dangerfile.status_report[:warnings][0]).to eq("APK permissions changed, see below. Should update `#{current_permission_file}` if it is intended change.")
          expect(dangerfile.status_report[:markdowns][0].message).not_to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Added')
        end
      end

      context 'Permission deleted' do
        let(:generated_permissions) do
          "package: com.mataku.scrobscrob.dev\n"
        end

        it do
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:warnings].length).to eq(1)
          expect(dangerfile.status_report[:warnings][0]).to include('APK permissions changed, see below.')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).not_to include('Added')
        end
      end

      context 'Permission added' do
        let(:generated_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='com.mataku.INTERNET'"
        end

        it do
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:warnings].length).to eq(1)
          expect(dangerfile.status_report[:warnings][0]).to include('APK permissions changed, see below.')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Added')
        end
      end

      context 'Report method set to fail' do
        let(:generated_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\nuses-permission: name='com.mataku.INTERNET'\n"
        end

        it 'should report errors' do
          plugin.report_method = 'fail'
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:errors].length).to eq(1)
          expect(dangerfile.status_report[:errors][0]).to eq("APK permissions changed, see below. Should update `#{current_permission_file}` if it is intended change.")
          expect(dangerfile.status_report[:messages].length).to eq(0)
          expect(dangerfile.status_report[:warnings].length).to eq(0)
          expect(dangerfile.status_report[:markdowns][0].message).not_to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Added')
        end
      end

      context 'Report method set to message' do
        let(:generated_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\nuses-permission: name='com.mataku.INTERNET'\n"
        end

        it 'should report messages' do
          plugin.report_method = 'message'
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:errors].length).to eq(0)
          expect(dangerfile.status_report[:messages].length).to eq(1)
          expect(dangerfile.status_report[:messages][0]).to eq("APK permissions changed, see below. Should update `#{current_permission_file}` if it is intended change.")
          expect(dangerfile.status_report[:warnings].length).to eq(0)
          expect(dangerfile.status_report[:markdowns][0].message).not_to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Added')
        end
      end

      context 'Report method set to warn' do
        let(:generated_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\nuses-permission: name='com.mataku.INTERNET'\n"
        end

        it 'should report warnings' do
          plugin.report_method = 'warn'
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:errors].length).to eq(0)
          expect(dangerfile.status_report[:messages].length).to eq(0)
          expect(dangerfile.status_report[:warnings].length).to eq(1)
          expect(dangerfile.status_report[:warnings][0]).to eq("APK permissions changed, see below. Should update `#{current_permission_file}` if it is intended change.")
          expect(dangerfile.status_report[:markdowns][0].message).not_to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Added')
        end
      end

      context 'Report method set to unknown' do
        let(:generated_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\nuses-permission: name='com.mataku.INTERNET'\n"
        end

        it 'should fail' do
          plugin.report_method = 'unknown'
          expect { plugin.check(apk: apk, permission_list_file: current_permission_file) }.to raise_error("Unknown report method: unknown")
        end
      end
    end
  end
end
