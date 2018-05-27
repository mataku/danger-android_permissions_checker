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
      let(:current_permissions) do
        "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\n"
      end

      let(:generated_permissions_list) do
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
        allow_any_instance_of(Kernel).to receive(:`).with(aapt_command).and_return(current_permissions)
        allow(File).to receive_message_chain(:open, :readlines).with(current_permission_file).with(no_args).and_return(generated_permissions_list)
      end

      it do
        plugin.check(apk: apk, permission_list_file: current_permission_file)
        expect(dangerfile.status_report[:warnings].length).to eq(0)
      end

      context 'Permission deleted' do
        let(:current_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='android.permission.INTERNET'\nuses-permission: name='com.mataku.INTERNET'\n"
        end

        it do
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:warnings].length).to eq(1)
          expect(dangerfile.status_report[:warnings][0]).to eq('APK permissions changed, see below.')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).not_to include('Added')

        end
      end

      context 'Permission added' do
        let(:current_permissions) do
          "package: com.mataku.scrobscrob.dev\n"
        end

        it do
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:warnings].length).to eq(1)
          expect(dangerfile.status_report[:warnings][0]).to eq('APK permissions changed, see below.')
          expect(dangerfile.status_report[:markdowns][0].message).not_to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Added')
        end
      end

      context 'Permission added' do
        let(:current_permissions) do
          "package: com.mataku.scrobscrob.dev\nuses-permission: name='com.mataku.INTERNET'"
        end

        it do
          plugin.check(apk: apk, permission_list_file: current_permission_file)
          expect(dangerfile.status_report[:warnings].length).to eq(1)
          expect(dangerfile.status_report[:warnings][0]).to eq('APK permissions changed, see below.')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Deleted')
          expect(dangerfile.status_report[:markdowns][0].message).to include('Added')
        end
      end
    end
  end
end
