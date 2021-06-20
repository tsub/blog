resource "aws_amplify_app" "blog" {
  name                          = "blog"
  repository                    = "https://github.com/tsub/blog"
  access_token                  = var.GITHUB_TOKEN
  enable_auto_branch_creation   = true
  enable_branch_auto_deletion   = true
  auto_branch_creation_patterns = ["*", "*/**"]

  auto_branch_creation_config {
    enable_auto_build           = true
    enable_pull_request_preview = true
    enable_basic_auth           = true
    basic_auth_credentials      = base64encode("preview:preview")
  }

  build_spec = <<-EOT
    version: 0.1
    frontend:
      phases:
        preBuild:
          commands:
            # Overwrite pre-installed hugo with specific version
            - |
              curl -fsL -o /var/tmp/hugo.tar.gz "https://github.com/gohugoio/hugo/releases/download/v0.40.2/hugo_0.40.2_Linux-64bit.tar.gz"
              tar -zxvf /var/tmp/hugo.tar.gz -C /usr/local/bin
              hugo version
        build:
          commands:
            - |
              if [ "$${AWS_BRANCH}" = "master" ]; then
                hugo -b https://blog-test.tsub.me
              else
                hugo -b "https://$${AWS_BRANCH}.$${AWS_APP_ID}.amplifyapp.com"
              fi
      artifacts:
        baseDirectory: public
        files:
          - '**/*'
  EOT
}

resource "aws_amplify_branch" "production" {
  app_id                 = aws_amplify_app.blog.id
  branch_name            = "master"
  enable_basic_auth      = true
  basic_auth_credentials = base64encode("preview:preview")

  stage = "PRODUCTION"
}

resource "aws_amplify_domain_association" "blog" {
  app_id      = aws_amplify_app.blog.id
  domain_name = "tsub.me"

  sub_domain {
    branch_name = aws_amplify_branch.production.branch_name
    prefix      = "blog-test"
  }
}
