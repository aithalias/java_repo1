pipeline{
    agent none
	triggers {cron '''H H * * *'''
			  pollSCM '*/5 * * * *'
			  }
	environment{
	 STAGE_ONE = 'SCM_checkout'
	 STAGE_TWO = 'code_analysis'
	 STAGE_THREE = 'maven_build'
	 SSH_CREDS = credentials('ssh')
	}
	parameters {
        string(name: 'PERSON', defaultValue: 'Developer1', description: 'Who is executing the task?')

        booleanParam(name: 'BOOLEAN', defaultValue: true)

        choice(name: 'ENV', choices: ['Dev', 'QA', 'Production'], description: 'Testing in diff env')
    }
        stages{
            stage('git checkout'){
                agent{label 'agent3'}
                steps{
					echo "Executor : ${params.PERSON} in ${params.ENV}"
                    git 'https://github.com/aithalias/java_repo1.git'
					echo "Executing ${env.STAGE_ONE}"
                }
            }
            stage('Sonar analysis'){
                agent{label 'agent3'}
                steps{
                    withSonarQubeEnv('sonar'){
                    sh "mvn clean verify sonar:sonar -Dsonar.projectKey=assignment5"
					echo "executed ${env.STAGE_TWO}"
                    }
                }
            }
            stage('Build stage'){
                agent{label 'agent2'}
				when {
                expression {
					return currentBuild.resultIsBetterOrEqualTo('SUCCESS') &&
                    (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'dev')
                }
            }
                steps{
                    git 'https://github.com/aithalias/java_repo1.git'
                    sh "mvn clean install"
					echo "executed ${env.STAGE_THREE}"
                }
            }
            stage('Deploy to Tomcat'){
                agent{label 'agent2'}
				when {
                expression {
                    return currentBuild.resultIsBetterOrEqualTo('SUCCESS')
                }
            }
                steps{
					sh 'echo "SSH private key is located at $SSH_CREDS"'
                    sh 'echo "SSH user is $SSH_CREDS_USR"'
					sh 'mkdir -p versions'
					sh 'sudo cp target/*.war versions/works-with-heroku-$BUILD_ID.war'
                    sh "sudo cp versions/works-with-heroku-$BUILD_ID.war' /opt/tomcat/webapps/"
					echo "Deployed in ${params.ENV} environment"
                }
            }
        }
		post { 
        always { 
            script{
		timeout(time: 10, unit: 'MINUTES') {
              def approvalMailContent = """
              Project: ${env.JOB_NAME}
              Build Number: ${env.BUILD_NUMBER}
              Go to build URL and check the console output.
              URL de build: ${env.BUILD_URL}
              """
			  mail(
             to: 'aithal96.anil@gmail.com',
             subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", 
             body: approvalMailContent,
             mimeType: 'text/plain'
              )
		    }
	      }
        }
    }
}
