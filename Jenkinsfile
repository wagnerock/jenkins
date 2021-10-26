node {
    try {
      deleteDir()

      stage("SCM") {
        scmVars = checkout scm
        checkout([$class: 'GitSCM', branches: [[name: scmVars.GIT_BRANCH]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'JENKINS_BITBUCKET_SSL', url: 'ssh://git@tools.adidas-group.com:7999/mdm/newworldofscripts.git']]])
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
          '''
          PWSH_OUTPUT = readFile('powershell.txt').trim()
          echo "Powershell output is $PWSH_OUTPUT"
          }
          archiveArtifacts "Devices.csv"
      }
      


    deleteDir()
    } catch (e) {
        office365ConnectorSend message: "FAILED: Job '${env.JOB_NAME}' (${env.BUILD_URL})", status: "FAILURE", webhookUrl: 'https://outlook.office.com/webhook/9e83c580-28ad-4406-95ef-2d9830f38e80@3bfeb222-e42c-4535-aace-ea6f7751369b/JenkinsCI/ad9b82c59e6f46fdadf482fe9e07246a/b9ff622e-f01e-4dd1-94d5-bee57959200d'
        throw e
    }
}
