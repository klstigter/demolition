table 50613 "Opti Project Location"
{
    Caption = 'Project Location';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Location No.';
        }

        field(2; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }

        field(3; "Description 2"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description 2';
        }

        field(4; "Search Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Search Name';
        }

        field(5; Blocked; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Blocked';
        }

        field(10; "Location Type"; Enum "Opti Project Location Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Location Type';
        }

        field(11; Status; Enum "Opti Project Location Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Status';
        }

        field(12; "Parent Location No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Location No.';
            TableRelation = "Opti Project Location"."Location No.";
        }

        // ---------------------------------------------------
        // OWNERSHIP / RELATIONS
        // ---------------------------------------------------

        field(20; "Project No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Project No.';
            TableRelation = Job."No.";
        }

        field(21; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
        }

        field(22; "Vendor No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }

        field(23; "Workload No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Workload No.';
        }

        // ---------------------------------------------------
        // ADDRESS
        // ---------------------------------------------------

        field(30; Address; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Address';
        }

        field(31; "Address 2"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Address 2';
        }

        field(32; "Post Code"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Post Code';
            TableRelation = "Post Code";
        }

        field(33; City; Text[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'City';
        }

        field(34; County; Text[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'County';
        }

        field(35; "Country/Region Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }

        // ---------------------------------------------------
        // CONTACT
        // ---------------------------------------------------

        field(40; "Contact Person"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Contact Person';
        }

        field(41; "Phone No."; Text[30])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Phone No.';
        }

        field(42; "Mobile Phone No."; Text[30])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Mobile Phone No.';
        }

        field(43; "E-Mail"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
        }

        // ---------------------------------------------------
        // INVOICE / ADMINISTRATION
        // ---------------------------------------------------

        field(50; "Invoice E-Mail"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Invoice E-Mail';
            ExtendedDatatype = EMail;
        }

        field(51; "Invoice E-Mail 2"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Invoice E-Mail 2';
            ExtendedDatatype = EMail;
        }

        field(52; "Invoice CC E-Mail"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Invoice CC E-Mail';
        }

        field(53; "Invoice Contact Person"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Invoice Contact Person';
        }

        field(54; "Purchase Order Required"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Purchase Order Required';
        }

        field(55; "Purchase Order No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Purchase Order No.';
        }

        field(56; "Invoice Reference"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice Reference';
        }

        field(57; "Cost Center Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Cost Center Code';
        }

        field(58; "External Project Code"; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'External Project Code';
        }

        // ---------------------------------------------------
        // LOCATION FLAGS
        // ---------------------------------------------------

        field(70; "Is Physical Location"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Physical Location';
        }

        field(71; "Is Administrative Location"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Administrative Location';
        }

        field(72; "Is Invoice Destination"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Invoice Destination';
        }

        field(73; "Is Delivery Location"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Delivery Location';
        }

        field(74; "Is Execution Location"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Execution Location';
        }

        field(75; "Is Meeting Location"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Meeting Location';
        }

        field(76; "Is Temporary Location"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Temporary Location';
        }

        // ---------------------------------------------------
        // OPERATIONAL
        // ---------------------------------------------------

        field(80; Capacity; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Capacity';
        }

        field(81; "Default Duration"; Duration)
        {
            DataClassification = CustomerContent;
            Caption = 'Default Duration';
        }

        field(82; "Requires Access Approval"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Requires Access Approval';
        }

        field(83; "Access Instructions"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Access Instructions';
            SubType = Memo;
        }

        field(84; "Parking Available"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Parking Available';
        }

        field(85; "Warehouse Location Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Warehouse Location Code';
            TableRelation = Location.Code;
        }

        // ---------------------------------------------------
        // GPS / MAPS
        // ---------------------------------------------------

        field(90; Latitude; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Latitude';
            DecimalPlaces = 0 : 8;
        }

        field(91; Longitude; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Longitude';
            DecimalPlaces = 0 : 8;
        }

        field(92; "Navigation URL"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Navigation URL';
        }

        field(93; "Geofence Radius (m)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Geofence Radius (m)';
        }

        // ---------------------------------------------------
        // PLANNING
        // ---------------------------------------------------

        field(100; "Default Resource No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Resource No.';
            TableRelation = Resource."No.";
        }

        field(101; "Preferred Vendor No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Preferred Vendor No.';
            TableRelation = Vendor."No.";
        }

        field(102; "Planning Priority"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Planning Priority';
        }

        field(103; "Time Zone"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Time Zone';
        }

        // ---------------------------------------------------
        // SYSTEM
        // ---------------------------------------------------

        field(200; "Created Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Created Date Time';
            Editable = false;
        }

        field(201; "Created By User"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Created By User';
            Editable = false;
        }

        field(202; "Last Modified Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Last Modified Date Time';
            Editable = false;
        }

        field(203; "Last Modified By User"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Last Modified By User';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Location No.")
        {
            Clustered = true;
        }

        key(Key1; "Project No.", "Location Type")
        {
        }

        key(Key2; "Customer No.", "Location Type")
        {
        }

        key(Key3; "Vendor No.", "Location Type")
        {
        }

        key(Key4; "Parent Location No.")
        {
        }

        key(Key5; City)
        {
        }

        key(Key6; Blocked)
        {
        }
    }

    trigger OnInsert()
    begin
        "Created Date Time" := CurrentDateTime();
        "Created By User" := UserId;

        "Last Modified Date Time" := CurrentDateTime();
        "Last Modified By User" := UserId;
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime();
        "Last Modified By User" := UserId;
    end;
}