// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

// <auto-generated/>

#nullable disable

namespace Azure.ResourceManager.CosmosDB.Models
{
    /// <summary> A private endpoint connection. </summary>
    public partial class PrivateEndpointConnection : Resource
    {
        /// <summary> Initializes a new instance of PrivateEndpointConnection. </summary>
        public PrivateEndpointConnection()
        {
        }

        /// <summary> Initializes a new instance of PrivateEndpointConnection. </summary>
        /// <param name="id"> Fully qualified resource Id for the resource. Ex - /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}. </param>
        /// <param name="name"> The name of the resource. </param>
        /// <param name="type"> The type of the resource. Ex- Microsoft.Compute/virtualMachines or Microsoft.Storage/storageAccounts. </param>
        /// <param name="privateEndpoint"> Private endpoint which the connection belongs to. </param>
        /// <param name="privateLinkServiceConnectionState"> Connection State of the Private Endpoint Connection. </param>
        internal PrivateEndpointConnection(string id, string name, string type, PrivateEndpointProperty privateEndpoint, PrivateLinkServiceConnectionStateProperty privateLinkServiceConnectionState) : base(id, name, type)
        {
            PrivateEndpoint = privateEndpoint;
            PrivateLinkServiceConnectionState = privateLinkServiceConnectionState;
        }

        /// <summary> Private endpoint which the connection belongs to. </summary>
        public PrivateEndpointProperty PrivateEndpoint { get; set; }
        /// <summary> Connection State of the Private Endpoint Connection. </summary>
        public PrivateLinkServiceConnectionStateProperty PrivateLinkServiceConnectionState { get; set; }
    }
}
