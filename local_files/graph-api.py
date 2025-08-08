import os
from azure.identity import ClientSecretCredential
from kiota_authentication_azure.azure_identity_authentication_provider import AzureIdentityAuthenticationProvider
from msgraph import GraphServiceClient, GraphRequestAdapter

from msgraph_core import GraphClientFactory, NationalClouds
from kiota_abstractions.api_error import APIError
import asyncio

# tenant_id     = os.getenv('AZURE_TENANT_ID', 'YOUR_TENANT_ID')
# client_id     = os.getenv('AZURE_CLIENT_ID', 'YOUR_CLIENT_ID')
# client_secret = os.getenv('AZURE_CLIENT_SECRET_ID', 'YOUR_SECRET')
# scopes = ['https://graph.microsoft.com/.default']
#
# # credential = CertificateCredential(tenant_id=tenant_id,client_id=client_id,)
# credential = ClientSecretCredential(tenant_id=tenant_id,client_id=client_id,client_secret=client_secret)
# # auth_provider = AzureIdentityAuthenticationProvider(credential,scopes)
# auth_provider = AzureIdentityAuthenticationProvider(credential, scopes=scopes)
# http_client = GraphClientFactory.create_with_default_middleware(host=NationalClouds.Global)
# request_adapter = GraphRequestAdapter(auth_provider, http_client)
#
# # Build the Kiota auth provider and disable CAE with is_cae_enabled=False:contentReference[oaicite:2]{index=2}
# graph_client = GraphServiceClient(request_adapter=request_adapter)
# async def me():
#     try:
#         mee = await graph_client.me.get()
#         if mee:
#             print(mee.display_name)
#     except APIError as e:
#         print(f"Error fetching user: {e.message}")
# asyncio.run(me())


async def get_user_info():
    tenant_id     = os.getenv('AZURE_TENANT_ID', 'YOUR_TENANT_ID')
    client_id     = os.getenv('AZURE_CLIENT_ID', 'YOUR_CLIENT_ID')
    client_secret = os.getenv('AZURE_CLIENT_SECRET_ID', 'YOUR_SECRET')
    scopes = ['https://graph.microsoft.com/.default']
    # Create async credential object
    credential = ClientSecretCredential(
        tenant_id=tenant_id,
        client_id=client_id,
        client_secret=client_secret
    )

    # Create Graph client with the async credential
    client = GraphServiceClient(credential)

    try:
        # Get user by UPN (User Principal Name)
        user = await client.users.by_user_id("bamideleomonayin@gmail.com").get()

        print("\nUser Information:")
        print(f"Display Name: {user.display_name}")
        print(f"Email: {user.mail or user.user_principal_name}")
        print(f"ID: {user.id}")
        print(f"Job Title: {user.job_title or 'N/A'}")
        print(f"Department: {user.department or 'N/A'}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # IMPORTANT: Close the credential when done
        await credential.close()


# Run the async function
asyncio.run(get_user_info())