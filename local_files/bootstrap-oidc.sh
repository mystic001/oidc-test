#!/bin/bash

set -euo pipefail

echo "🛠️ GitHub OIDC App Registration Bootstrap Script"

# Prompt for required inputs
read -p "Enter App Registration name (e.g. GitHub-OIDC): " APP_NAME
read -p "Enter your GitHub repo (e.g. mystic001/oidc-test): " GITHUB_REPO
read -p "Enter the branch to allow (e.g. main): " BRANCH
read -p "Enter the subscription ID (e.g. 12345678-1234-1234-1234-123456789012): " SUBSCRIPTION_ID

SUBJECT="repo:${GITHUB_REPO}:ref:refs/heads/${BRANCH}"
SECRET1="AZURE_CLIENT_ID"
SECRET2="AZURE_TENANT_ID"
SECRET3="AZURE_SUBSCRIPTION_ID"
API_ID="00000003-0000-0000-c000-000000000000"
APPLICATION_READ_ALL="1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
DIRECTORY_READ_ALL="19dbc75e-c2e2-444c-a770-ec69d8559fc7"

# Check dependencies
command -v az >/dev/null || { echo "❌ Azure CLI (az) is not installed."; exit 1; }
command -v jq >/dev/null || { echo "❌ jq is not installed."; exit 1; }
command -v gh >/dev/null || { echo "❌ GitHub CLI (gh) is not installed."; exit 1; }

echo "Your subject is: ${SUBJECT}"

echo "🔐 Logging in to Azure..."
az account show > /dev/null || az login

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)
# Create the app registration
APP_INFO=$(az ad app create --display-name "$APP_NAME")
# Extract the appId from APP_INFO
APP_ID=$(echo "$APP_INFO" | jq -r '.appId')
# Get the object ID using the app ID
OBJECT_ID=$(echo "$APP_INFO" | jq -r '.objectId')

echo "App Info: $APP_INFO"
echo "App ID: $APP_ID"
echo "Object ID: $OBJECT_ID"
echo "Tenant ID: $TENANT_ID"

# Sanity check
if [[ -z "$APP_ID" || "$APP_ID" == "null" || -z "$OBJECT_ID" || "$OBJECT_ID" == "null" ]]; then
  echo "❌ Failed to retrieve valid App ID or Object ID"
  exit 1
fi

echo "✅ App created:"
echo "Client ID: $APP_ID"
echo "Object ID: $OBJECT_ID"
echo "Tenant ID: $TENANT_ID"

# Get access token for Microsoft Graph
GRAPH_TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)

# Add federated identity credential
echo "🔗 Adding federated identity credential for: $SUBJECT..."
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/applications/${OBJECT_ID}/federatedIdentityCredentials" \
  --headers "Authorization=Bearer $GRAPH_TOKEN" "Content-Type=application/json" \
  --body "{
    \"name\": \"GitHubOIDC-${BRANCH}\",
    \"displayName\": \"GitHubOIDC-${APP_NAME}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"${SUBJECT}\",
    \"description\": \"OIDC federated login for GitHub Actions\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

#Create Service Principal
az ad sp create --id "$APP_ID"
az ad sp show --id "$APP_ID"


# Assign Contributor role to Service Principal
az role assignment create --assignee "$OBJECT_ID" --role "Contributor" --scope "/subscriptions/$SUBSCRIPTION_ID"

# Assign Graph API permissions
echo "🔒 Assigning Microsoft Graph permissions..."
echo "Using APP_ID: '$APP_ID'"
az ad app permission add --id "$APP_ID" \
  --api $API_ID \
  --api-permissions $APPLICATION_READ_ALL=Role


echo "🔒 Assigning Microsoft Graph permissions..."
az ad app permission add --id "$APP_ID" \
  --api $API_ID \
  --api-permissions $DIRECTORY_READ_ALL=Role


  # Grant admin consent
echo "🛡️ Granting admin consent..."
az ad app permission admin-consent --id "$APP_ID"


# Save secrets to GitHub
echo "📤 Saving secrets to GitHub repository: $GITHUB_REPO..."
gh secret set "$SECRET1" --repo "$GITHUB_REPO" --body "$APP_ID"
gh secret set "$SECRET2" --repo "$GITHUB_REPO" --body "$TENANT_ID"
gh secret set "$SECRET3" --repo "$GITHUB_REPO" --body "$SUBSCRIPTION_ID"
echo ""
echo "✅ Setup complete!"
echo "🔐 Saved secrets:"
echo "- $SECRET1 = $APP_ID"
echo "- $SECRET2 = $TENANT_ID"
echo "- $SECRET3 = $SUBSCRIPTION_ID"
echo ""
echo "🎯 You can now use OIDC login in GitHub Actions for '$GITHUB_REPO' on branch '$BRANCH'"



# Create Service Principal