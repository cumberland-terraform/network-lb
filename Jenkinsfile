pipeline {
	agent { 
		label 						'jenkins-slave-java' 
	}
	
	environment { 
		BITBUCKET_KEY 				= credentials('mdtjenkinsbgit')
		EMAIL_LIST 					= 'grant.moore@maryland.gov,aaron.ramirez@maryland.gov,aasritha.kilari@maryland.gov,'
		MODULE_NAME 				= 'lb'
		OS_ARCH 					= 'amd64' 
		TF_LOG 						= 'WARN'
		TF_VER 						= '1.8.5'
	}

	stages {
		stage('Credentials') {
			steps {
				sh 	'''
					mkdir ~/.ssh
					touch ~/.ssh/id_rsa
					cat $(echo $BITBUCKET_KEY) > ~/.ssh/id_rsa
					chmod 400 ~/.ssh/id_rsa
					ssh-keyscan -t rsa source.mdthink.maryland.gov >> ~/.ssh/known_hosts
				'''
			}
		}

		stage ('Base Dependencies') {
			steps{
				sh '''
					wget -q https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${OS_ARCH}.zip
        			unzip -o terraform_${TF_VER}_linux_${OS_ARCH}.zip
        			sudo cp -rf terraform /usr/local/bin/
        			terraform --version
				'''
			}
		}

		stage ('Feature Branch Dependencies') {
			when { expression {env.GIT_BRANCH =~ "origin/feature/*" || env.GIT_BRANCH =~ "origin/*PR*"} }
			steps {
				sh '''
					curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
					tflint --version

					curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
					tfsec --version
				'''
			}
		}

		stage ('Master Branch Dependencies') {
			when { expression {env.GIT_BRANCH =~ "origin/master/*" } }
			steps {
				sh '''
					curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.18.0/terraform-docs-v0.18.0-$(uname)-amd64.tar.gz
					tar -xzf terraform-docs.tar.gz
					chmod +x terraform-docs
					sudo mv terraform-docs /usr/local/bin/terraform-docs
					terraform-docs --version
				'''
			}
		}

		stage ('Lint') {
			when { expression {env.GIT_BRANCH =~ "origin/feature/*" || env.GIT_BRANCH =~ "origin/*PR*"} }
			steps {
				sh '''
					tflint \
						--init \
						--config .ci/.tflint.hcl 
					tflint \
						-f json \
						--config .ci/.tflint.hcl \
						> lint.json
				'''
			}
			post {
				always {
					sh '''
						cat lint.json
						aws s3 cp lint.json s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/lint/${JOB_NAME}/${BUILD_NUMBER}_lint_$(date +%s).json
					'''
				}
			}
		}

		stage ('Sec Scanning') {
			when { expression {env.GIT_BRANCH =~ "origin/feature/*" || env.GIT_BRANCH =~ "origin/*PR*" } }
		    steps {
				sh '''
				    tfsec . \
						--format json \
						--no-colour \
						--tfvars-file ./.ci/tests/idengr.tfvars \
						> sec.json
				'''
			post {
				always {
					sh '''						
						cat sec.json
						aws s3 cp sec.json s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/sec/${JOB_NAME}/${BUILD_NUMBER}_sec_$(date +%s).json
					'''
					}
				}
			}
		}	

		stage ('Test') {
			when { expression {env.GIT_BRANCH =~ "origin/feature/*" || env.GIT_BRANCH =~ "origin/*PR*"} }
			steps {
				sh '''
					terraform init \
						-no-color
					terraform test \
						-test-directory ./.ci/tests \
						-json \
						> test.json
					'''
			post {
				always {
					sh '''
						cat test.json
						aws s3 cp test.json s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/test/${JOB_NAME}/${BUILD_NUMBER}_test_$(date +%s).json
					'''
					}
				}
			}
		}
		
		stage ('Document') {
			when { expression {env.GIT_BRANCH =~ "origin/master/*" } }
			steps {
				sh '''
					terraform-docs \
						-c .ci/.tfdocs_md.yml .
					aws s3 cp \
						tfdocs.md \
						s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/tfdocs/${BUILD_NUMBER}_tfdocs_$(date +%s).md
					terraform-docs \
						-c .ci/.tfdocs_json.yml .
					aws s3 cp \
						tfdocs.json \
						s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/tfdocs/${BUILD_NUMBER}_tfdocs_$(date +%s).json
				'''
			}
		}
	}

	post {
        failure {
            emailext body: '$BUILD_URL to view the results.',
            to:   EMAIL_LIST,
            subject: 'Build failed in Jenkins: $PROJECT_NAME - #$BUILD_NUMBER'
        }
        success {
            emailext body: '$BUILD_URL to view the results.',
            to:   EMAIL_LIST,
            subject: 'Build succeeded in Jenkins: $PROJECT_NAME - #$BUILD_NUMBER'
        }
    }
}
