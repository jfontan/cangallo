# vim:ts=2:sw=2

#$: << 'lib/cangallo'
require 'spec_helper'

require 'qcow2'
require 'fileutils'

IMAGE_SIZE = 100 * 1024 * 1024

describe Cangallo::Qcow2 do
  before :all do
    @tmpdir = Dir.mktmpdir('qcow2')
  end

  after :all do
    FileUtils.rm_rf(@tmpdir)
  end

  context 'creating the base image' do
    before :all do
      @qcow2_path = File.join(@tmpdir, 'base.qcow2')
      Cangallo::Qcow2.create(@qcow2_path, nil, IMAGE_SIZE) # 100 Mb

      q = Cangallo::Qcow2.new(@qcow2_path)

      @raw_path = File.join(@tmpdir, 'base.raw')

      f = File.open(@raw_path, 'w')
      f.seek(IMAGE_SIZE - 1)
      f.write("\x00")
      f.close
    end

    it 'should be able to create it' do
      expect(File).to exist(@qcow2_path)
      expect(File).to exist(@raw_path)
    end

    it 'should get proper info (qcow2)' do
      qcow2 = Cangallo::Qcow2.new(@qcow2_path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(IMAGE_SIZE)
      expect(info['cluster-size']).to eq(65_536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200_704)
    end

    it 'should get proper info (raw)' do
      qcow2 = Cangallo::Qcow2.new(@raw_path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(IMAGE_SIZE)
      expect(info['cluster-size']).to eq(nil)
      expect(info['format']).to eq('raw')
      expect(info['actual-size']).to eq(4096)
    end

    it 'should be able to compute sha1 (qcow2)' do
      qcow2 = Cangallo::Qcow2.new(@qcow2_path)

      sha1 = qcow2.sha1
      expect(sha1).to eq('2c2ceccb5ec5574f791d45b63c940cff20550f9a')
    end

    it 'should be able to compute sha1 (raw)' do
      qcow2 = Cangallo::Qcow2.new(@raw_path)

      sha1 = qcow2.sha1
      expect(sha1).to eq('2c2ceccb5ec5574f791d45b63c940cff20550f9a')
    end
  end

  context 'with the child image' do
    before :all do
      @qcow2_path = File.join(@tmpdir, 'child_qcow2.qcow2')
      @raw_path = File.join(@tmpdir, 'child_raw.qcow2')
      # 200 Mb
      Cangallo::Qcow2.create(@qcow2_path, File.join(@tmpdir, 'base.qcow2'), 2 * IMAGE_SIZE)
      Cangallo::Qcow2.create(@raw_path, File.join(@tmpdir, 'base.raw'), 2 * IMAGE_SIZE)
    end

    it 'should be able to create it' do
      expect(File).to exist(@qcow2_path)
      expect(File).to exist(@raw_path)
    end

    it 'should get proper info (qcow2)' do
      qcow2 = Cangallo::Qcow2.new(@qcow2_path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(2 * IMAGE_SIZE)
      expect(info['cluster-size']).to eq(65_536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200_704)
      expect(File.basename(info['backing-filename'])).to eq('base.qcow2')
      expect(File.basename(info['backing-filename-format'])).to eq('qcow2')
    end

    it 'should get proper info (raw)' do
      qcow2 = Cangallo::Qcow2.new(@raw_path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(2 * IMAGE_SIZE)
      expect(info['cluster-size']).to eq(65_536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200_704)
      expect(File.basename(info['backing-filename'])).to eq('base.raw')
      expect(File.basename(info['backing-filename-format'])).to eq('raw')
    end

    it 'should be able to compute sha1 (qcow2)' do
      qcow2 = Cangallo::Qcow2.new(@qcow2_path)

      sha1 = qcow2.sha1
      expect(sha1).to eq('fd7c5327c68fcf94b62dc9f58fc1cdb3c8c01258')
    end

    it 'should be able to compute sha1 (raw)' do
      qcow2 = Cangallo::Qcow2.new(@raw_path)

      sha1 = qcow2.sha1
      expect(sha1).to eq('fd7c5327c68fcf94b62dc9f58fc1cdb3c8c01258')
    end
  end
end
