# vim:ts=2:sw=2

#$: << 'lib/cangallo'
require 'spec_helper'

require 'qcow2'
require 'fileutils'
require 'systemu'

IMAGE_SIZE = 1 * 1024 * 1024
SHA_1 = '3b71f43ff30f4b15b5cd85dd9e95ebc7e84eb5a3'
SHA_2 = '7d76d48d64d7ac5411d714a4bb83f37e3e5b8df6'

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
      expect(sha1).to eq(SHA_1)
    end

    it 'should be able to compute sha1 (raw)' do
      qcow2 = Cangallo::Qcow2.new(@raw_path)

      sha1 = qcow2.sha1
      expect(sha1).to eq(SHA_1)
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
      expect(sha1).to eq(SHA_2)
    end

    it 'should be able to compute sha1 (raw)' do
      qcow2 = Cangallo::Qcow2.new(@raw_path)

      sha1 = qcow2.sha1
      expect(sha1).to eq(SHA_2)
    end
  end

  context 'image actions' do
    before :all do
      @qcow2_path = File.join(@tmpdir, 'base.qcow2')
      @raw_path = File.join(@tmpdir, 'base.raw')
      @parent_path = File.join(@tmpdir, 'child_qcow2.qcow2')
    end

    it 'should be able to create it' do
      expect(File).to exist(@qcow2_path)
      expect(File).to exist(@raw_path)
    end

    it 'should be able to copy it (qcow2)' do
      path = File.join(@tmpdir, 'copy_qcow2_copy.qcow2')
      q = Cangallo::Qcow2.new(@qcow2_path)
      q.copy(path, { parent: @qcow2_path })

      expect(File).to exist(path)

      info = Cangallo::Qcow2.new(path).info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(IMAGE_SIZE)
      expect(info['cluster-size']).to eq(65_536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(266_240)
      expect(File.basename(info['backing-filename'])).to eq('base.qcow2')
      expect(File.basename(info['backing-filename-format'])).to eq('qcow2')
    end

    it 'should be able to copy it (raw)' do
      path = File.join(@tmpdir, 'copy_raw_copy.qcow2')
      q = Cangallo::Qcow2.new(@raw_path)
      q.copy(path, { parent: @raw_path })

      expect(File).to exist(path)

      info = Cangallo::Qcow2.new(path).info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(IMAGE_SIZE)
      expect(info['cluster-size']).to eq(65_536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(266_240)
      expect(File.basename(info['backing-filename'])).to eq('base.raw')
      expect(File.basename(info['backing-filename-format'])).to eq('raw')
    end

    it 'should be able to sparsify it (qcow2)' do
      path = File.join(@tmpdir, 'sparsify.qcow2')
      q = Cangallo::Qcow2.new(@parent_path)
      q.sparsify(path)

      expect(File).to exist(path)

      info = Cangallo::Qcow2.new(path).info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(2 * IMAGE_SIZE)
      expect(info['cluster-size']).to eq(65_536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200_704)
      expect(info['backing-filename']).to eq(nil)
      expect(info['backing-filename-format']).to eq(nil)
    end
  end

  context 'different backing image formats' do
    before :all do
      formats = ['qcow', 'qcow2', 'qed', 'raw', 'vmdk', 'vdi', 'vhdx']
      @images = []

      formats.each do |format|
        name = File.join(@tmpdir, "base_format.#{format}")
        @images << name
        cmd = "qemu-img create -f #{format} #{name} #{IMAGE_SIZE}"
        pr = systemu cmd
        expect(pr[0].success?).to eq(true)
      end
    end

    it 'should be able to create chained images' do
      @images.each do |image|
        name = "#{image}.chained"
        Cangallo::Qcow2.create(name, image, IMAGE_SIZE)
      end
    end
  end
end
