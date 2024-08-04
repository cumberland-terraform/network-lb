pipeline {
	agent { 
		label						'jenkins-slave-java' 
	}
	
	environment { 
		BITBUCKET_KEY				= credentials('mdtjenkinsbgit')
		EMAIL_LIST 					= 'grant.moore@maryland.gov,aaron.ramirez@maryland.gov'
		MODULE_NAME 				= 'lb'
		OS_ARCH 					= 'amd64' 
		TF_LOG 						= 'WARN'
		TF_VER 						= '1.8.5'
	}
	
	stages {
		stage('Credentials') {
			steps {
				sh '''
					mkdir ~/.ssh
					touch ~/.ssh/id_rsa
					cat $(echo $BITBUCKET_KEY) > ~/.ssh/id_rsa
					chmod 400 ~/.ssh/id_rsa
					ssh-keyscan -t rsa source.mdthink.maryland.gov >> ~/.ssh/known_hosts
				'''
				}
			}
		}

		stage ('Dependencies') {
			steps {
				sh '''
					wget -q https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${OS_ARCH}.zip
        			unzip -o terraform_${TF_VER}_linux_${OS_ARCH}.zip
        			sudo cp -rf terraform /usr/local/bin/
        			terraform --version

					curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
					tflint --version

					curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
					tfsec --version

					curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.18.0/terraform-docs-v0.18.0-$(uname)-amd64.tar.gz
					tar -xzf terraform-docs.tar.gz
					chmod +x terraform-docs
					sudo mv terraform-docs /usr/local/bin/terraform-docs
					terraform-docs --version
				'''
			}
		}

		/*
		Uses  force tag to return 0 exit code even when
		issues are found. ONLY DURING INITIAL DEV
		*/
		stage ('Lint') {
			steps {
				sh '''
					tflint \
						--init \
						--config .ci/.tflint.hcl 
					tflint \
						-f json \
						--config .ci/.tflint.hcl \
						> lint.json
					aws s3 cp lint.json s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/lint/${BUILD_NUMBER}_lint_$(date +%s).json
				'''
			}
		}

		stage ('Sec Scanning') {
		    steps {
				sh '''
				    tfsec . \
						--format json \
						--no-colour \
						--soft-fail \
						--tfvars-file ./.ci/tests/idengr.tfvars
							> sec.json
					aws s3 cp sec.json s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/sec/${BUILD_NUMBER}_sec_$(date +%s).json
				'''
			}
		}

		stage ('Test') {
			steps {
				sh '''
					terraform init \
						-no-color
					terraform test \
						-test-directory ./.ci/tests \
						-json > test.json || true
					aws s3 cp test.json s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/test/${BUILD_NUMBER}_test_$(date +%s).json
				'''
			}
		}

		stage ('Document') {
			when { expression { env.GIT_BRANCH == "master" } }

			steps {
				sh '''
					terraform-docs \
						-c .ci/.tfdocs_md.yml .
					aws s3 cp tfdocs.md s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/tfdocs/${BUILD_NUMBER}_tfdocs_$(date +%s).md
				'''
				sh '''
					terraform-docs \
						-c .ci/.tfdocs_json.yml .
					aws s3 cp tfdocs.json s3://s3-score1-mdt-eter-pipeline/${MODULE_NAME}/tfdocs/${BUILD_NUMBER}_tfdocs_$(date +%s).json
				'''
			}
		}
	}

	post {
        failure {
            emailext body: 'Check console output at $BUILD_URL to view the results. \n\n ${CHANGES} \n\n [JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO] \n${BUILD_LOG_REGEX,regex="ERROR", escapeHtml=false}',
            to:   EMAIL_LIST,
            subject: 'Build failed in Jenkins: $PROJECT_NAME - #$BUILD_NUMBER'
        }
        success {
            emailext body: 'Check console output at $BUILD_URL to view the results.  \n\n ${CHANGES} \n\n [JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO][JOB-INFO] \n${BUILD_LOG, maxLines=100, escapeHtml=false}',
            to:   EMAIL_LIST,
            subject: 'Build succeeded in Jenkins: $PROJECT_NAME - #$BUILD_NUMBER'
        }
    }
}
