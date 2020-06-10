// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

// <auto-generated/>

#nullable disable

namespace Azure.Management.Network.Models
{
    /// <summary> The information of an AvailablePrivateEndpointType. </summary>
    public partial class AvailablePrivateEndpointType
    {
        /// <summary> Initializes a new instance of AvailablePrivateEndpointType. </summary>
        internal AvailablePrivateEndpointType()
        {
        }

        /// <summary> Initializes a new instance of AvailablePrivateEndpointType. </summary>
        /// <param name="name"> The name of the service and resource. </param>
        /// <param name="id"> A unique identifier of the AvailablePrivateEndpoint Type resource. </param>
        /// <param name="type"> Resource type. </param>
        /// <param name="resourceName"> The name of the service and resource. </param>
        internal AvailablePrivateEndpointType(string name, string id, string type, string resourceName)
        {
            Name = name;
            Id = id;
            Type = type;
            ResourceName = resourceName;
        }

        /// <summary> The name of the service and resource. </summary>
        public string Name { get; }
        /// <summary> A unique identifier of the AvailablePrivateEndpoint Type resource. </summary>
        public string Id { get; }
        /// <summary> Resource type. </summary>
        public string Type { get; }
        /// <summary> The name of the service and resource. </summary>
        public string ResourceName { get; }
    }
}