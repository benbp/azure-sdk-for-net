// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

// <auto-generated/>

#nullable disable

namespace Azure.ResourceManager.Network.Models
{
    /// <summary> Trusted Root certificates properties for tls. </summary>
    public partial class FirewallPolicyCertificateAuthority
    {
        /// <summary> Initializes a new instance of FirewallPolicyCertificateAuthority. </summary>
        public FirewallPolicyCertificateAuthority()
        {
        }

        /// <summary> Initializes a new instance of FirewallPolicyCertificateAuthority. </summary>
        /// <param name="name"> Name of the CA certificate. </param>
        /// <param name="keyVaultSecretId"> Secret Id of (base-64 encoded unencrypted pfx) &apos;Secret&apos; or &apos;Certificate&apos; object stored in KeyVault. </param>
        internal FirewallPolicyCertificateAuthority(string name, string keyVaultSecretId)
        {
            Name = name;
            KeyVaultSecretId = keyVaultSecretId;
        }

        /// <summary> Name of the CA certificate. </summary>
        public string Name { get; set; }
        /// <summary> Secret Id of (base-64 encoded unencrypted pfx) &apos;Secret&apos; or &apos;Certificate&apos; object stored in KeyVault. </summary>
        public string KeyVaultSecretId { get; set; }
    }
}