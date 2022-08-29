declare global {
    namespace NodeJS {
        interface ProcessEnv {
            AZURE_VAULT_ID: string;
            AZURE_KEY_ID: string;
            AZURE_CLIENT_ID: string;
            AZURE_TENANT_ID: string;
            ICP_URL: string;
        }
    }
}

export {}
