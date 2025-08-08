import os

from azure.core.credentials import TokenCredential
from azure.identity import ClientSecretCredential, AzureAuthorityHosts
from kiota_authentication_azure.azure_identity_authentication_provider import AzureIdentityAuthenticationProvider
from msgraph import GraphServiceClient, GraphRequestAdapter

from msgraph_core import GraphClientFactory
from kiota_abstractions.api_error import APIError
import asyncio


tenant_id     = os.getenv('AZURE_TENANT_ID', 'YOUR_TENANT_ID')
client_id     = os.getenv('AZURE_CLIENT_ID', 'YOUR_CLIENT_ID')
scopes = ['https://graph.microsoft.com/.default']

credential = ClientSecretCredential(tenant_id=tenant_id,client_id=client_id)
auth_provider = AzureIdentityAuthenticationProvider(credential,scopes)

# Use the .default scope for US Gov Graph:contentReference[oaicite:1]{index=1}


# Build the Kiota auth provider and disable CAE with is_cae_enabled=False:contentReference[oaicite:2]{index=2}
client = GraphServiceClient(credentials=credential, scopes=scopes)
async def me():
    try:
        mee = await client.me.get()
        if mee:
            print(mee.display_name)
    except APIError as e:
        print(f"Error fetching user: {e.message}")
asyncio.run(me())