// SPDX-License-Identifier: MIT
// Copyright 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
// Build signed i.MX images with kas and Yocto
pipeline {
    agent { dockerfile true }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        gitParameter branchFilter: 'origin/(.*)', defaultValue: 'wrynose', selectedValue: 'DEFAULT', name: 'BRANCH', type: 'PT_BRANCH', description: 'branch to build'
        choice choices: ['imx95-15x15-lpddr4x-frdm', 'imx93-11x11-lpddr4x-frdm', 'imx91-11x11-lpddr4-frdm'], description: 'select machine', name: 'MACHINE'
        choice choices: ['dev', 'prod'], description: 'select security profile', name: 'SECURITY_PROFILE'
        choice choices: ['no', 'yes'], description: 'clean workspace before building', name: 'CLEAN'
        string defaultValue: '7e17c332-9a25-4c95-90a7-f487ebf44714', description: 'i.MX secure boot signing keys', name: 'SIGNING_KEYS_CREDENTIAL'
    }

    environment {
        KAS_CLONE_DEPTH = '1'
        KAS_MACHINE = "${params.MACHINE}"
        KAS_TARGET = 'imx-secure-image'
        SECURITY_PROFILE = "${params.SECURITY_PROFILE}"
    }

    stages {
        // Use the branch checked out by the Jenkins job
        stage('Clean') {
            when {
                expression { params.CLEAN == 'yes' }
            }
            steps {
                sh 'git clean -fdx'
            }
        }

        stage('Setup') {
            steps {
                withCredentials([file(credentialsId: params.SIGNING_KEYS_CREDENTIAL, variable: 'KEYS_TARBALL')]) {
                    sh 'tar xzf "$KEYS_TARBALL"'
                }
                sh 'tools/generate-signing-keys.sh'
            }
        }

        stage('Build image') {
            steps {
                sh 'kas build --force-checkout --update kas-imx-secure.yml:kas-signing-keys.yml'
                archiveArtifacts artifacts: "build/tmp/deploy/images/${params.MACHINE}/imx-secure-image-${params.MACHINE}.rootfs-*-${params.SECURITY_PROFILE}.*," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-boot*.sign," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-boot*.sign.fuses/*," +
                                            "build/tmp/deploy/images/${params.MACHINE}/fitImage",
                                 excludes: '**/*.ext3,**/*.ext4,**/*.wic,**/*.erofs,**/*.erofs.avbverity',
                                 followSymlinks: false,
                                 fingerprint: true,
                                 onlyIfSuccessful: true
            }
        }
    }
}
