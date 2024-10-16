# KMS Key for ECS Task Execution

- Alias: alias/fcdemo-kms-key

## 暗号化

```bash
aws kms encrypt --key-id alias/fcdemo-kms-key --plaintext "暗号化したい文字列" --query CiphertextBlob --output text --cli-binary-format raw-in-base64-out > enc.txt
```

暗号化された文字列は長くなっている事が多いため、一度ファイルに保存しています (`enc.txt`)。

## 復号

一度保存したファイルを読み込ませて復号します。

```bash
$ aws kms decrypt --ciphertext-blob fileb://<(cat enc.txt|base64 -d) --region ap-northeast-1 | jq .Plaintext --raw-output | base64 -d
```

# ECR

- Repository: fcdemo-base
- URL: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com

## ログイン

```bash
$ AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
$ aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin https://${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/fcdemo-base
```

# ECS

lifecycle > ignore_changes を指定しているため、revision が切り替わらないことがあります。
revision を強制的に更新する場合は以下のコマンドを実行します。これはそのまま手動デプロイ手順になります。

- TASK_DEFINITION_ARN の例: "arn:aws:ecs:ap-northeast-1:123456789012:task-definition/fcdemo-task:2"

```bash
$ TASK_DEFINITION_ARN=$(aws ecs list-task-definitions --family-prefix fcdemo-task --sort DESC --max-items 1 --query 'taskDefinitionArns[0]' --output text)
$ aws ecs update-service --cluster fcdemo-ecs-cluster --service fcdemo-service --task-definition $TASK_DEFINITION_ARN --force-new-deployment
```
