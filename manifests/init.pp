# Manage phantomjs installation
#
# Old package build instructions from
# https://github.com/aeberhardo/phantomjs-linux-armv6l
# FIXME: In testing.
class phantomjs (
  $version = '2.2.1'
) {
  if $::architecture == 'armv7l' {
    $basedir = '/home/deploy/phantomjs'
    $pixman_baseurl = 'http://www.opensource.apple.com/source/X11libs/X11libs-60/pixman/pixman-0.20.2/pixman/'

    vcsrepo { $basedir:
      ensure   => present,
      provider => 'git',
      source   => 'https://github.com/ariya/phantomjs.git',
      revision => $version,
      depth    => 1,
      user     => 'deploy',
      notify   => Exec['phantomjs-build'],
    }

    file { "${basedir}/src/qt/src/3rdparty/pixman":
      ensure  => directory,
      owner   => 'deploy',
      group   => 'deploy',
      mode    => '0755',
      require => Vcsrepo[$basedir],
    }

    exec { 'fetch pixman-arm-neon-asm.h':
      command => "/usr/bin/curl -O ${basedir}/src/qt/src/3rdparty/pixman/pixman-arm-neon-asm.h ${pixman_baseurl}/pixman-arm-neon-asm.h?txt",
      creates => "${basedir}/src/qt/src/3rdparty/pixman/pixman-arm-neon-asm.h",
      require => File["${basedir}/src/qt/src/3rdparty/pixman"],
    }

    exec { 'fetch pixman-arm-neon-asm.S':
      command => "/usr/bin/curl -O ${basedir}/src/qt/src/3rdparty/pixman/pixman-arm-neon-asm.h ${pixman_baseurl}/pixman-arm-neon-asm.S?txt",
      creates => "${basedir}/src/qt/src/3rdparty/pixman/pixman-arm-neon-asm.S",
      require => File["${basedir}/src/qt/src/3rdparty/pixman"],
    }

    exec { 'phantomjs-build':
      cwd         => '/home/deploy/phantomjs',
      path        => '/bin:/usr/bin:/usr/local/bin',
      command     => './build.sh --confirm',
      timeout     => 0,
      refreshonly => true,
      require     => [Vcsrepo[$basedir], Exec['fetch pixman-arm-neon-asm.h'], Exec['fetch pixman-arm-neon-asm.S']],
      notify      => Exec['phantomjs-install'],
    }

    exec { 'phantomjs-install':
      command => '/usr/bin/install -o root -g root -m 755 /home/deploy/phantomjs/bin/phantomjs /usr/bin',
      require => Exec['phantomjs-build'],
      creates => '/usr/bin/phantomjs',
    }
  } elsif $::architecture == 'amd64' {
    $filename = "phantomjs-${version}-linux-x86_64.tar.bz2"

    exec { "/usr/bin/wget -O - https://bitbucket.org/ariya/phantomjs/downloads/${filename} | /bin/tar jxf - --strip-component 2 -C /usr/local/bin/ phantomjs-${version}-linux-x86_64/bin/phantomjs":
      creates => '/usr/local/bin/phantomjs',
    }
  } else {
    fail "Architecture (${::architecture}) not supported"
  }
}
