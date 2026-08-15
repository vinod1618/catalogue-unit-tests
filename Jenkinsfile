pipeline {
    agent {
        node {
            label 'roboshop' 
        } 
    }
    environment {
        appVersion = ""
        ACC_ID = "315281578625"
        region = "us-east-1"
    }
    options {
        //disableConcurrentBuilds()
        timeout(time: 5, unit: 'MINUTES')
    }
    /* parameters {
        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
        text(name: 'BIOGRAPHY', defaultValue: '', description: 'Enter some information about the person')
        booleanParam(name: 'DEPLOY', defaultValue: false, description: 'Toggle this value')
        choice(name: 'CHOICE', choices: ['One', 'Two', 'Three'], description: 'Pick something')
        password(name: 'PASSWORD', defaultValue: 'SECRET', description: 'Enter a password')
    } */
    stages {
        stage('Read version'){
            steps {
                script {
                    // Load and parse the JSON file
                    def packageJson = readJSON file: 'package.json'
                    
                    // Access fields directly
                    appVersion = packageJson.version
                    echo "Building version ${appVersion}"
                }
            }
        }
        // stage('Install Dependencies') {
        //     steps {
        //         script{
        //             sh """
        //                 npm install
        //             """
        //         }
        //     }
        // }

        stage('unit test') {
            steps {
                script{
                    sh """
                        npm test
                    """ 
                }
            }
        }


        // stage ('SonarQube Analysis'){
        //     steps {
        //         script {
        //             def scannerHome = tool name: 'sonar-8' // agent configuration
        //             withSonarQubeEnv('sonar-server') { // analysing and uploading to server
        //                 sh "${scannerHome}/bin/sonar-scanner"
        //             }
        //         }
        //     }
        // }
        // stage("Quality Gate") {
        //     steps {
        //       timeout(time: 1, unit: 'HOURS') {
        //         waitForQualityGate abortPipeline: true
        //       }
        //     }
        // }

        stage('Dependabot Security Check') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'github-token',
                        variable: 'GITHUB_TOKEN'
                    )
                ]) {
                    script {
                        def response = sh(
                            script: '''
                                curl -sS \
                                -H "Accept: application/vnd.github+json" \
                                -H "Authorization: Bearer $GITHUB_TOKEN" \
                                -H "X-GitHub-Api-Version: 2026-03-10" \
                                "https://api.github.com/repos/vinod1618/catalogue-unit-tests/dependabot/alerts?state=open&severity=high,critical&per_page=100"
                            ''',
                            returnStdout: true
                        ).trim()

                        if (!response.startsWith("[")) {
                            error "Failed to fetch Dependabot alerts from GitHub: ${response}"
                        }

                        def alerts = readJSON text: response

                        if (alerts.size() > 0) {
                            echo "❌ High/Critical Dependabot vulnerabilities found: ${alerts.size()}"

                            alerts.each { alert ->
                                echo "Package: ${alert.dependency.package.name}"
                                echo "Severity: ${alert.security_advisory.severity}"
                                echo "CVE: ${alert.security_advisory.cve_id ?: 'N/A'}"
                                echo "GHSA: ${alert.security_advisory.ghsa_id}"
                            }

                            error "Pipeline failed: High/Critical Dependabot vulnerabilities detected."
                        }

                        echo "✅ No open High/Critical Dependabot vulnerabilities found."
                    }
                }
            }
}

        
        stage('Build Image') {
            steps {
               script{
                    withAWS(credentials: 'aws-creds', region: "${region}") {
                        // Commands here have AWS authentication
                        sh """
                            aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com
                            docker build -t ${ACC_ID}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion} .
                            docker push ${ACC_ID}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion}
                        """
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                sh """
                    # Download HTML template
                    wget -q -O html.tpl \
                        https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl

                    # Generate HTML report
                    trivy image \
                        --scanners vuln \
                        --pkg-types os \
                        --severity HIGH,MEDIUM,CRITICAL \
                        --exit-code 1 \
                        --format table \
                        ${ACC_ID}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion}

                    # Security gate
                    # Pipeline fails if HIGH or CRITICAL vulnerabilities exist
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --format table \
                        ${ACC_ID}.dkr.ecr.${region}.amazonaws.com/roboshop/catalogue:${appVersion}
                """
            }
        }

}

    // post build
    post { 
        always { 
            echo 'I will always say Hello again!'
            cleanWs()
        }
        success {
            echo "pipeline success"
        }
        failure {
            echo "pipeline failure"
        }
    }
}