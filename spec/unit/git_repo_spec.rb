require_relative '../spec_helper'

describe Dapp::GitRepo do
  include SpecHelpers::Common
  include SpecHelpers::Application
  include SpecHelpers::Git

  before :each do
    stub_application
  end

  def init!(git_dir=nil)
    git_init!(git_dir: git_dir)
    expect(File.exist?(file_path(git_dir, '.git'))).to be_truthy
  end

  def config
    {}
  end

  def commit!(data, git_dir=nil)
    @commit_counter ||= 1
    text_txt = file_path(git_dir, 'test.txt')

    if !File.exist?(text_txt) || File.read(text_txt) != data
      @commit_counter += 1
      File.write text_txt, data
    end

    git_commit!(git_dir: git_dir)
    expect(`git -C #{file_path(git_dir, '.git')} rev-list --all --count`).to eq "#{@commit_counter}\n"
  end

  def file_path(git_dir, arg)
    git_dir.nil? ? arg : File.join(git_dir, arg)
  end

  def latest_commit
    git_latest_commit
  end

  def remote_init!
    init!('remote')
  end

  def remote_commit!(data)
    commit!(data, 'remote')
  end

  def dapp_remote_init(**kwargs)
    remote_init!
    remote_commit!('Some text')
    @remote = Dapp::GitRepo::Remote.new(application, 'local_remote', url: 'remote/.git', **kwargs)
    expect(File.exist?('local_remote.git')).to be_truthy
  end

  def dapp_remote_cleanup
    @remote.cleanup!
    expect(File.exist?('local_remote')).to be_falsy
    expect(File.exist?('remote.git')).to be_falsy
  end

  it 'Remote#init', test_construct: true do
    dapp_remote_init
    dapp_remote_cleanup
  end

  it 'Remote#ssh', test_construct: true do
    shellout 'ssh-keygen -b 1024 -f key -P ""'
    dapp_remote_init ssh_key_path: 'key'
    dapp_remote_cleanup
  end

  it 'Remote#fetch', test_construct: true do
    dapp_remote_init
    remote_commit!('Some another text')
    @remote.fetch!
    expect(`git -C local_remote.git rev-list --all --count`).to eq "#{@commit_counter}\n"
    dapp_remote_cleanup
  end

  it 'Own', test_construct: true do
    init!
    commit!('Some text')

    own = Dapp::GitRepo::Own.new(application)
    expect(own.latest_commit).to eq git_latest_commit

    commit!('Some another text')
    expect(own.latest_commit).to eq git_latest_commit
  end
end