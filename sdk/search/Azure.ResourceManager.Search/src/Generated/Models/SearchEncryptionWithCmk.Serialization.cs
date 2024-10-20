// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

// <auto-generated/>

#nullable disable

using System.Text.Json;
using Azure.Core;

namespace Azure.ResourceManager.Search.Models
{
    public partial class SearchEncryptionWithCmk : IUtf8JsonSerializable
    {
        void IUtf8JsonSerializable.Write(Utf8JsonWriter writer)
        {
            writer.WriteStartObject();
            if (Optional.IsDefined(Enforcement))
            {
                writer.WritePropertyName("enforcement"u8);
                writer.WriteStringValue(Enforcement.Value.ToSerialString());
            }
            writer.WriteEndObject();
        }

        internal static SearchEncryptionWithCmk DeserializeSearchEncryptionWithCmk(JsonElement element)
        {
            if (element.ValueKind == JsonValueKind.Null)
            {
                return null;
            }
            Optional<SearchEncryptionWithCmkEnforcement> enforcement = default;
            Optional<SearchEncryptionComplianceStatus> encryptionComplianceStatus = default;
            foreach (var property in element.EnumerateObject())
            {
                if (property.NameEquals("enforcement"u8))
                {
                    if (property.Value.ValueKind == JsonValueKind.Null)
                    {
                        property.ThrowNonNullablePropertyIsNull();
                        continue;
                    }
                    enforcement = property.Value.GetString().ToSearchEncryptionWithCmkEnforcement();
                    continue;
                }
                if (property.NameEquals("encryptionComplianceStatus"u8))
                {
                    if (property.Value.ValueKind == JsonValueKind.Null)
                    {
                        property.ThrowNonNullablePropertyIsNull();
                        continue;
                    }
                    encryptionComplianceStatus = property.Value.GetString().ToSearchEncryptionComplianceStatus();
                    continue;
                }
            }
            return new SearchEncryptionWithCmk(Optional.ToNullable(enforcement), Optional.ToNullable(encryptionComplianceStatus));
        }
    }
}
