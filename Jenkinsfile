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
        booleanParam defaultValue: false, description: 'use AHAB SoftHSM signing keys', name: 'AHAB_SOFTHSM'
    }

    environment {
        KAS_CLONE_DEPTH = '1'
        KAS_MACHINE = "${params.MACHINE}"
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
                script {
                    env.KAS_BUILD_CONFIG = 'kas-imx-secure.yml:kas-signing-keys.yml'
                    if (params.AHAB_SOFTHSM) {
                        sh '''
                            set -eu
                            if [ ! -d imx-softhsm-ahab ] || [ ! -f kas-softhsm-ahab.yml ]; then
                                tools/generate-softhsm-ahab-keys.py
                            fi
                        '''
                        env.KAS_BUILD_CONFIG += ':kas-softhsm-ahab.yml'
                    }
                    writeFile file: 'build/kas-ci.yml',
                              text: "header:\n  version: 14\n" +
                                    "machine: ${params.MACHINE}\n"
                }
                sh '''
                    kas dump --force-checkout --update \
                        --resolve-refs --resolve-local --resolve-env \
                        "$KAS_BUILD_CONFIG:build/kas-ci.yml" > build/kas-resolved.yml
                '''
            }
        }

        stage('Build image') {
            steps {
                script {
                    if (params.SECURITY_PROFILE == 'prod') {
                        // Remove old reports so this build gets a fresh scan
                        sh '''
                            rm -f "build/tmp/deploy/images/$KAS_MACHINE/trowl/imx-secure-image-base-$KAS_MACHINE.rootfs/index.html" \
                                  "build/tmp/deploy/images/$KAS_MACHINE/trowl/imx-secure-image-base-$KAS_MACHINE.rootfs/report.json" \
                                  "build/tmp/deploy/images/$KAS_MACHINE/trowl/imx-secure-image-base-$KAS_MACHINE.rootfs/scan.log"
                        '''
                    }
                }
                sh 'kas build build/kas-resolved.yml'
                sh 'install -m 0644 build/kas-resolved.yml "build/tmp/deploy/images/$KAS_MACHINE/kas-resolved.yml"'
                archiveArtifacts artifacts: "build/tmp/deploy/images/${params.MACHINE}/kas-resolved.yml," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-secure-image-base-${params.MACHINE}.rootfs-${params.SECURITY_PROFILE}_*.wic.*," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-secure-image-base-${params.MACHINE}.rootfs-${params.SECURITY_PROFILE}_*.sbom-cve-check.*.json," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-secure-image-base-${params.MACHINE}.rootfs-${params.SECURITY_PROFILE}_*.manifest," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-secure-image-base-update-${params.MACHINE}.rootfs-${params.SECURITY_PROFILE}_*.swu," +
                                            "build/tmp/deploy/images/${params.MACHINE}/flash-emmc-${params.MACHINE}.uuu," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-boot*.sign," +
                                            "build/tmp/deploy/images/${params.MACHINE}/imx-boot*.fuses/*," +
                                            "build/tmp/deploy/images/${params.MACHINE}/fitImage," +
                                            "build/tmp/deploy/images/${params.MACHINE}/fitImage.ahab",
                                 followSymlinks: false,
                                 fingerprint: true,
                                 onlyIfSuccessful: true
                script {
                    if (params.SECURITY_PROFILE == 'prod') {
                        archiveArtifacts artifacts: "build/tmp/deploy/images/${params.MACHINE}/trowl/imx-secure-image-base-${params.MACHINE}.rootfs/index.html," +
                                                    "build/tmp/deploy/images/${params.MACHINE}/trowl/imx-secure-image-base-${params.MACHINE}.rootfs/report.json," +
                                                    "build/tmp/deploy/images/${params.MACHINE}/trowl/imx-secure-image-base-${params.MACHINE}.rootfs/scan.log",
                                         allowEmptyArchive: true,
                                         followSymlinks: false,
                                         fingerprint: true,
                                         onlyIfSuccessful: true
                    }
                }
            }
        }
    }
}
