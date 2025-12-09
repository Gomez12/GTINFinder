#!/usr/bin/env python3
"""
Authentik OIDC Setup Script for GTINFinder
This script creates an OAuth2 Provider and Application via Django management commands
"""

import os
import sys
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentik.root.settings')
django.setup()

from authentik.core.models import Application, User
from authentik.providers.oauth2.models import OAuth2Provider, ClientTypes, JWTAlgorithms, RedirectURI
from authentik.flows.models import Flow
from django.db import transaction

def create_oidc_provider_and_app():
    """Create OAuth2 Provider and Application for GTINFinder"""
    
    print("🔧 Creating Authentik OAuth2 Provider and Application for GTINFinder...")
    
    try:
        # Get admin user
        admin_user = User.objects.get(username='akadmin')
        print(f"✅ Found admin user: {admin_user.username}")
        
        # Get default authentication flow
        auth_flow = Flow.objects.filter(slug='default-authentication-flow').first()
        if not auth_flow:
            print("❌ Default authentication flow not found")
            return False
        print(f"✅ Found authentication flow: {auth_flow.name}")
        
        with transaction.atomic():
            # Check if provider already exists
            existing_provider = OAuth2Provider.objects.filter(name='GTINFinder').first()
            if existing_provider:
                print(f"⚠️  Provider 'GTINFinder' already exists")
                provider = existing_provider
            else:
                # Create OAuth2 Provider
                provider = OAuth2Provider.objects.create(
                    name='GTINFinder',
                    authorization_flow=auth_flow,
                    client_type=ClientTypes.CONFIDENTIAL,
                    jwt_alg=JWTAlgorithms.RS256,
                    sub_mode='user_id',
                    issuer_mode='per_provider',
                )
                
                # Add redirect URIs
                RedirectURI.objects.create(
                    provider=provider,
                    url='http://localhost:3000/*',
                    matching_mode=RedirectURI.Mode.STRICT
                )
                RedirectURI.objects.create(
                    provider=provider,
                    url='http://localhost:3000/silent-renew.html',
                    matching_mode=RedirectURI.Mode.STRICT
                )
                
                print(f"✅ Created OAuth2 Provider: {provider.name}")
                print(f"   Client ID: {provider.client_id}")
                print(f"   Client Secret: {provider.client_secret}")
            
            # Check if application already exists
            existing_app = Application.objects.filter(slug='gtin-finder').first()
            if existing_app:
                print(f"⚠️  Application 'gtin-finder' already exists")
                app = existing_app
            else:
                # Create Application
                app = Application.objects.create(
                    name='GTINFinder',
                    slug='gtin-finder',
                    provider=provider,
                    launch_url='http://localhost:3000',
                    policy_engine_mode='any',
                )
                print(f"✅ Created Application: {app.name}")
                print(f"   Slug: {app.slug}")
            
            print("\n🎉 Authentik OIDC setup completed successfully!")
            print("\n📋 Configuration Details:")
            print(f"   Provider Name: {provider.name}")
            print(f"   Client ID: {provider.client_id}")
            print(f"   Client Secret: {provider.client_secret}")
            print(f"   Application Slug: {app.slug}")
            print(f"   Authorization URL: http://localhost:9000/application/o/authorize/")
            print(f"   Token URL: http://localhost:9000/application/o/token/")
            print(f"   UserInfo URL: http://localhost:9000/application/o/userinfo/")
            print(f"   Issuer URL: http://localhost:9000/application/o/gtin-finder/")
            print(f"   JWKS URL: http://localhost:9000/application/o/gtin-finder/jwks/")
            print(f"   End Session URL: http://localhost:9000/application/o/gtin-finder/end-session/")
            
            print("\n🔗 OIDC Discovery Endpoint:")
            print(f"   http://localhost:9000/application/o/gtin-finder/.well-known/openid-configuration")
            
            print("\n🌐 Frontend Test URLs:")
            print(f"   Frontend: http://localhost:3000")
            print(f"   Login: http://localhost:3000/login")
            print(f"   Authentik Admin: http://localhost:9000/if/admin/")
            
            return True
            
    except Exception as e:
        print(f"❌ Error creating OIDC provider and application: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    success = create_oidc_provider_and_app()
    sys.exit(0 if success else 1)