node {
    try {
      deleteDir()

      stage("SCM") {
        scmVars = checkout scm
        checkout([$class: 'GitSCM', branches: [[name: scmVars.GIT_BRANCH]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[ url: 'https://github.com/wagnerock/jenkins.git']]])
      }
      stage("Get all devices") {
          withCredentials([
              string(credentialsId: 'INTUNE_APP_RELEASE_TENANT_ID_TEST_TENANT', variable: 'TENANT_ID'),
              string(credentialsId: 'INTUNE_APP_RELEASE_CLIENT_ID_TEST_TENANT', variable: 'APP_ID'),
              string(credentialsId: 'INTUNE_APP_RELEASE_CLIENT_SECRET_TEST_TENANT', variable: 'SECRET'),
          ]) {
          sh '''
              set +x

              /usr/local/bin/pwsh $WORKSPACE/intune/GetAllDevices.ps1 -ClientID ${APP_ID} -ClientSecret ${SECRET} -TenantId ${TENANT_ID}  > powershell.txt
              echo "$PWSH_OUTPUT"
          '''
          PWSH_OUTPUT = readFile('powershell.txt').trim()
          echo "Powershell output is $PWSH_OUTPUT"
          }
          archiveArtifacts "$WORKSPACE/Devices.csv"
      }
      


    deleteDir()
    } catch (e) {
        throw e
    }
}
