page 50699 "ProjectLocationApi Opt"
{
    PageType = API;
    Caption = 'Project Location API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'ProjectLocation';
    EntitySetName = 'ProjectLocations';
    SourceTable = "Project Location";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(locationNo_; Rec."Location No.")
                {
                    Caption = 'Location No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(searchName; Rec."Search Name")
                {
                    Caption = 'Search Name';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(locationType; Rec."Location Type")
                {
                    Caption = 'Location Type';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(parentLocationNo_; Rec."Parent Location No.")
                {
                    Caption = 'Parent Location No.';
                }
                field(projectNo_; Rec."Project No.")
                {
                    Caption = 'Project No.';
                }
                field(customerNo_; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(vendorNo_; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                }
                field(workloadNo_; Rec."Workload No.")
                {
                    Caption = 'Workload No.';
                }
                field(address; Rec.Address)
                {
                    Caption = 'Address';
                }
                field(address2; Rec."Address 2")
                {
                    Caption = 'Address 2';
                }
                field(postCode; Rec."Post Code")
                {
                    Caption = 'Post Code';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(county; Rec.County)
                {
                    Caption = 'County';
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(contactPerson; Rec."Contact Person")
                {
                    Caption = 'Contact Person';
                }
                field(phoneNo_; Rec."Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(mobilePhoneNo_; Rec."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                }
                field(email; Rec."E-Mail")
                {
                    Caption = 'E-Mail';
                }
                field(invoiceEmail; Rec."Invoice E-Mail")
                {
                    Caption = 'Invoice E-Mail';
                }
                field(invoiceEmail2; Rec."Invoice E-Mail 2")
                {
                    Caption = 'Invoice E-Mail 2';
                }
                field(invoiceCcEmail; Rec."Invoice CC E-Mail")
                {
                    Caption = 'Invoice CC E-Mail';
                }
                field(invoiceContactPerson; Rec."Invoice Contact Person")
                {
                    Caption = 'Invoice Contact Person';
                }
                field(purchaseOrderRequired; Rec."Purchase Order Required")
                {
                    Caption = 'Purchase Order Required';
                }
                field(purchaseOrderNo_; Rec."Purchase Order No.")
                {
                    Caption = 'Purchase Order No.';
                }
                field(invoiceReference; Rec."Invoice Reference")
                {
                    Caption = 'Invoice Reference';
                }
                field(costCenterCode; Rec."Cost Center Code")
                {
                    Caption = 'Cost Center Code';
                }
                field(externalProjectCode; Rec."External Project Code")
                {
                    Caption = 'External Project Code';
                }
                field(isPhysicalLocation; Rec."Is Physical Location")
                {
                    Caption = 'Is Physical Location';
                }
                field(isAdministrativeLocation; Rec."Is Administrative Location")
                {
                    Caption = 'Is Administrative Location';
                }
                field(isInvoiceDestination; Rec."Is Invoice Destination")
                {
                    Caption = 'Is Invoice Destination';
                }
                field(isDeliveryLocation; Rec."Is Delivery Location")
                {
                    Caption = 'Is Delivery Location';
                }
                field(isExecutionLocation; Rec."Is Execution Location")
                {
                    Caption = 'Is Execution Location';
                }
                field(isMeetingLocation; Rec."Is Meeting Location")
                {
                    Caption = 'Is Meeting Location';
                }
                field(isTemporaryLocation; Rec."Is Temporary Location")
                {
                    Caption = 'Is Temporary Location';
                }
                field(capacity; Rec.Capacity)
                {
                    Caption = 'Capacity';
                }
                field(defaultDuration; Rec."Default Duration")
                {
                    Caption = 'Default Duration';
                }
                field(requiresAccessApproval; Rec."Requires Access Approval")
                {
                    Caption = 'Requires Access Approval';
                }
                field(parkingAvailable; Rec."Parking Available")
                {
                    Caption = 'Parking Available';
                }
                field(warehouseLocationCode; Rec."Warehouse Location Code")
                {
                    Caption = 'Warehouse Location Code';
                }
                field(latitude; Rec.Latitude)
                {
                    Caption = 'Latitude';
                }
                field(longitude; Rec.Longitude)
                {
                    Caption = 'Longitude';
                }
                field(navigationUrl; Rec."Navigation URL")
                {
                    Caption = 'Navigation URL';
                }
                field(geofenceRadiusM; Rec."Geofence Radius (m)")
                {
                    Caption = 'Geofence Radius (m)';
                }
                field(defaultResourceNo_; Rec."Default Resource No.")
                {
                    Caption = 'Default Resource No.';
                }
                field(preferredVendorNo_; Rec."Preferred Vendor No.")
                {
                    Caption = 'Preferred Vendor No.';
                }
                field(planningPriority; Rec."Planning Priority")
                {
                    Caption = 'Planning Priority';
                }
                field(timeZone; Rec."Time Zone")
                {
                    Caption = 'Time Zone';
                }
                field(createdDateTime; Rec."Created Date Time")
                {
                    Caption = 'Created Date Time';
                }
                field(createdByUser; Rec."Created By User")
                {
                    Caption = 'Created By User';
                }
                field(lastModifiedDateTime; Rec."Last Modified Date Time")
                {
                    Caption = 'Last Modified Date Time';
                }
                field(lastModifiedByUser; Rec."Last Modified By User")
                {
                    Caption = 'Last Modified By User';
                }
            }
        }
    }
}
