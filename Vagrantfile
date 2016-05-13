#
# XNAT Vagrant project
# http://www.xnat.org
# Copyright (c) 2015-2016, Washington University School of Medicine, all rights reserved.
# Released under the Simplified BSD license.
#

unless defined?(cfg_dir)
    puts ''
    puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    puts ' Setup aborted...'
    puts ' VM setup must be done from within one of the folders in "configs".'
    puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    abort('')
end

require 'yaml'

# save the root 'multi' dir
multi_root = '../..'

# puts "multi_root is #{multi_root}"

Dir.mkdir("#{cwd}/.work") unless File.exists?("#{cwd}/.work")

# load config settings
puts "Loading #{cwd}/config.yaml for Vagrant configuration..."
profile    = YAML.load_file("#{cwd}/config.yaml")

# load local customizations
# (We really want to read these last, but we need to read the config file from here.)
local_path = "#{cwd}/local.yaml"
local      = {}
if File.exists? (local_path)
    puts "Loading local overrides from #{local_path}..."
    local = YAML.load_file(local_path)
    local.each { |k, v|
        profile[k] = v
    }
end

# setup some fallback defaults - some of these are for backwards compatibility
profile['project']       ||= profile['name']
profile['host']          ||= profile['name']
profile['admin']         ||= "admin@#{profile['server']}"
profile['vm_user']       ||= profile['project']
profile['data_root']     ||= "/data/#{profile['project']}"
profile['home']          ||= "#{profile['data_root']}/home"
profile['server']        ||= profile['vm_ip']
profile['revision']      ||= profile['xnat_rev'] ||= ''
profile['xnat_rev']      ||= profile['revision']
profile['pipeline_rev']  ||= profile['revision']

# this ugliness reconciles and conforms [xnat] and [xnat_dir]
profile['xnat'] = profile['xnat_dir'] ||= profile['xnat'] ||= 'xnat'

# reconciles and conforms [pipeline_inst] and [pipeline_dir]
profile['pipeline_inst'] = profile['pipeline_dir'] ||= profile['pipeline_inst'] ||= 'pipeline'

profile['config']        ||= cfg_dir ||= ''
profile['provision']     ||= ''
profile['build']         ||= ''

if profile['host'] == ''
    profile['host'] = profile['name']
end

if profile['server'] == ''
    profile['server'] = profile['vm_ip']
end

if profile['xnat_url']
    profile['xnat_src'] = profile['xnat_url']
end

if profile['pipeline_url']
    profile['pipeline_src'] = profile['pipeline_url']
end

File.open("#{cwd}/.work/vars.sh", 'wb') { |vars|
    vars.truncate(0)
    vars.puts("#!/bin/bash\n")
    profile.each { |k, v|
        vars.puts "#{k.upcase}='#{v}'"
    }
}

File.open("#{cwd}/.work/vars.sed", 'wb') { |vars|
    vars.truncate(0)
    profile.each { |k, v|
        # Only put v in the sed file if it's a string. No subs for hashes.
        if v.is_a?(String)
            vars.puts "s/@#{k.upcase}@/#{v.gsub('/', "\\/")}/g"
        end
    }
}

shares = profile['shares'] ||= profile['shared'] ||= profile['share']
has_shares = shares && shares != 'false'

VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    config.vm.define "#{profile['name']}"

    config.vm.box     = profile['box']
    config.vm.box_url = profile['box_url']

    config.vm.network 'private_network', ip: profile['vm_ip']
    config.vm.hostname = profile['host']

    config.vm.provider 'virtualbox' do |v|
        v.name   = profile['name']
        v.memory = profile['ram']
        v.cpus   = profile['cpus']
        v.gui    = profile['gui']
    end

    # set the 'xnat-vagrant-multi' folder as a share
    config.vm.synced_folder "#{multi_root}", '/vagrant-multi'

    # Will only run on initial 'up'
    if profile['provision'] != ''
        # since this Vagrantfile is eval'd in the config's Vagrantfile,
        # this path is actually in the config's folder
        provision_script = "#{profile['provision']}"
        # look for provision script in config folder first
        unless File.exists? (provision_script)
            provision_script = "#{multi_root}/#{profile['provision']}"
        end
        config.vm.provision :shell, path: provision_script
    end

    if ARGV[0] != 'up' && ARGV[0] != 'destroy'

        config.ssh.username = profile['vm_user']

        # if profile['xnat_src'] == ''
        #     abort("No XNAT source defined in ")
        # end

        # (unless there's an 'xnat_url' property, do this)
        unless profile['xnat_url']
            config.vm.synced_folder profile['xnat_src'], "#{profile['data_root']}/src/#{profile['xnat_dir']}"
        end

        unless profile['pipeline_url']
            if profile['pipeline_src'] && profile['pipeline_src'] != ''
                config.vm.synced_folder profile['pipeline_src'], "#{profile['data_root']}/src/#{profile['pipeline_dir']}"
            end
        end

        if has_shares
            shares.each { |share, share_to|
                puts "Setting up share from #{share} to #{share_to[0]}"
                config.vm.synced_folder share, share_to[0], mount_options: share_to[1]
            }
        end

        # Will only run on initial 'up'
        if profile['build'] != ''
            # since this Vagrantfile is eval'd in the config's own Vagrantfile,
            # this path is actually in the config's folder
            build_script = "#{profile['build']}"
            # look for provision script in config folder first
            unless File.exists? (build_script)
                build_script = "#{multi_root}/#{profile['build']}"
            end

            # Additional provisioners, called explicitly by "--provision-with foo"
            config.vm.provision 'build', type: :shell, path: build_script, privileged: false
            # config.vm.provision 'quick-deploy', type: :shell, path: '/vagrant-multi/scripts/quick-deploy.sh', privileged: false
            # config.vm.provision 'quick-deploy-templates', type: :shell, path: '/vagrant-multi/scripts/quick-deploy-templates.sh', privileged: false
            # config.vm.provision 'gradle-build', type: :shell, path: '/vagrant-multi/scripts/gradle-build.sh', privileged: false

        end

    end

end
