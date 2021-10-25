node {
    try {
      deleteDir()

      stage("SCM") {
        scmVars = checkout scm
        checkout([$class: 'GitSCM', branches: [[name: scmVars.GIT_BRANCH]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'JENKINS_BITBUCKET_SSL', url: 'ssh://git@github.com:wagnerock/jenkins.git']]])
      }
      stage("Get all devices") {
          withCredentials([
              string(credentialsId: 'INTUNE_APP_RELEASE_TENANT_ID_TEST_TENANT', variable: 'TENANT_ID'),
              string(credentialsId: 'INTUNE_APP_RELEASE_CLIENT_ID_TEST_TENANT', variable: 'APP_ID'),
              string(credentialsId: 'INTUNE_APP_RELEASE_CLIENT_SECRET_TEST_TENANT', variable: 'SECRET'),
          ]) {
          sh '''
              set +x

              PWSH_OUTPUT = /usr/local/bin/pwsh $WORKSPACE/intune/GetAllDevices.ps1 -ClientID ${APP_ID} -ClientSecret ${SECRET} -TenantId ${TENANT_ID} 
              echo "$PWSH_OUTPUT"
          '''

          }
      }
      stage("Upload it to Intune") {
          withCredentials([
              string(credentialsId: 'ADIDAS_ARTIFACTORY_DEPLOYER', variable: 'PW1'),
              string(credentialsId: 'INTUNE_APP_RELEASE_TENANT_ID_PROD_TENANT', variable: 'TENANT_ID'),
              string(credentialsId: 'INTUNE_APP_RELEASE_CLIENT_ID_PROD_TENANT', variable: 'APP_ID'),
              string(credentialsId: 'INTUNE_APP_RELEASE_CLIENT_SECRET_PROD_TENANT', variable: 'SECRET'),
          ]) {
              APP_NAME = readFile('app_name.txt').trim()
              echo "The APP_NAME is $APP_NAME"
              APP_BUNDLE_ID = readFile('app_bundle_id.txt').trim()
              echo "The APP_BUNDLE_ID is $APP_BUNDLE_ID"
              BUNDLE_VERSION = readFile('bundle_version.txt').trim()
              echo "The BUNDLE_VERSION is $BUNDLE_VERSION"
              APP_VERSION = readFile('app_version.txt').trim()
              echo "The APP_VERSION is $APP_VERSION"
              APP_NAME = readFile('app_name.txt').trim()
              echo "The APP_NAME is $APP_NAME"
              search_result_output = readFile('search_result_output.txt').trim()
              echo "The search_result_output is $search_result_output"
              search_result_id = readFile('search_result_id.txt').trim()
              echo "The search_result_id is $search_result_id"
              EXISTINGID = readFile('search_result_id.txt').trim()
              echo "The EXISTINGID is $EXISTINGID"
              sh '''
                  set +x
                  # ARTIFACT_URI=$(<artifact_uri.txt)
                  APP_NAME=$(<app_name.txt)
                  APP_BUNDLE_ID=$(<app_bundle_id.txt)
                  #curl -s -u${PW1} ${ARTIFACT_URI} -O
                  FILE_TO_UPLOAD=$(ls *.ipa)
                  APP_VERSION=$(<app_version.txt)
                  BUNDLE_VERSION=$(<bundle_version.txt)
                  MINIMUM_IOS_VERSION=$(<minimum_ios_version.txt)
                  EXPIRATION_DATE=$(unzip -p $FILE_TO_UPLOAD \\*/embedded.mobileprovision | grep -a -A 2 ExpirationDate | grep date | sed -e 's/^.*<date>\\(.*\\)<\\/date>/\\1/')
                  echo "EXPIRATION_DATE is $EXPIRATION_DATE"
                  DEVICE_FAMILY=$(/Users/Shared/Jenkins/Home/scripts/newworldofscripts/upload/device_family_checker ${FILE_TO_UPLOAD})
                  EXISTINGID=$(<search_result_id.txt)
                  /usr/local/bin/pwsh $WORKSPACE/upload/deploy.ps1 -ClientID ${APP_ID} -ClientSecret ${SECRET} -TenantId ${TENANT_ID} -FileName $FILE_TO_UPLOAD -DisplayName "$APP_NAME" -Publisher Adidas -Description Adidas -BundleId "$APP_BUNDLE_ID" -IdentityVersion "$APP_VERSION" -VersionNumber "$BUNDLE_VERSION" -ExpirationDateTime "$EXPIRATION_DATE" -ExistingId "$EXISTINGID"
                  rm $FILE_TO_UPLOAD
              '''
          }
      }


    deleteDir()
    } catch (e) {
        //office365ConnectorSend message: "FAILED: Job '${env.JOB_NAME}' (${env.BUILD_URL})", status: "FAILURE", webhookUrl: 'https://outlook.office.com/webhook/9e83c580-28ad-4406-95ef-2d9830f38e80@3bfeb222-e42c-4535-aace-ea6f7751369b/JenkinsCI/ad9b82c59e6f46fdadf482fe9e07246a/b9ff622e-f01e-4dd1-94d5-bee57959200d'
        throw e
    }
}
