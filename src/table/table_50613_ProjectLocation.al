table 50613 "Project Location"
{
    Caption = 'Project Location';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location No."; Code[20])
        {
            Caption = 'Location No.';
        }

        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }

        field(3; "Description 2"; Text[100])
        {
            Caption = 'Description 2';
        }

        field(4; "Search Name"; Text[100])
        {
            Caption = 'Search Name';
        }

        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }

        field(10; "Location Type"; Enum "Project Location Type")
        {
            Caption = 'Location Type';
        }

        field(11; Status; Enum "Project Location Status")
        {
            Caption = 'Status';
        }

        field(12; "Parent Location No."; Code[20])
        {
            Caption = 'Parent Location No.';
            TableRelation = "Project Location"."Location No.";
        }

        // ---------------------------------------------------
        // OWNERSHIP / RELATIONS
        // ---------------------------------------------------

        field(20; "Project No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No.";
        }

        field(21; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
        }

        field(22; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }

        field(23; "Workload No."; Code[20])
        {
            Caption = 'Workload No.';
        }

        // ---------------------------------------------------
        // ADDRESS
        // ---------------------------------------------------

        field(30; Address; Text[100])
        {
            Caption = 'Address';
        }

        field(31; "Address 2"; Text[100])
        {
            Caption = 'Address 2';
        }

        field(32; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
        }

        field(33; City; Text[50])
        {
            Caption = 'City';
        }

        field(34; County; Text[50])
        {
            Caption = 'County';
        }

        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }

        // ---------------------------------------------------
        // CONTACT
        // ---------------------------------------------------

        field(40; "Contact Person"; Text[100])
        {
            Caption = 'Contact Person';
        }

        field(41; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
        }

        field(42; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
        }

        field(43; "E-Mail"; Text[100])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
        }

        // ---------------------------------------------------
        // INVOICE / ADMINISTRATION
        // ---------------------------------------------------

        field(50; "Invoice E-Mail"; Text[100])
        {
            Caption = 'Invoice E-Mail';
            ExtendedDatatype = EMail;
        }

        field(51; "Invoice E-Mail 2"; Text[100])
        {
            Caption = 'Invoice E-Mail 2';
            ExtendedDatatype = EMail;
        }

        field(52; "Invoice CC E-Mail"; Text[250])
        {
            Caption = 'Invoice CC E-Mail';
        }

        field(53; "Invoice Contact Person"; Text[100])
        {
            Caption = 'Invoice Contact Person';
        }

        field(54; "Purchase Order Required"; Boolean)
        {
            Caption = 'Purchase Order Required';
        }

        field(55; "Purchase Order No."; Code[50])
        {
            Caption = 'Purchase Order No.';
        }

        field(56; "Invoice Reference"; Text[100])
        {
            Caption = 'Invoice Reference';
        }

        field(57; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
        }

        field(58; "External Project Code"; Code[50])
        {
            Caption = 'External Project Code';
        }

        // ---------------------------------------------------
        // LOCATION FLAGS
        // ---------------------------------------------------

        field(70; "Is Physical Location"; Boolean)
        {
            Caption = 'Is Physical Location';
        }

        field(71; "Is Administrative Location"; Boolean)
        {
            Caption = 'Is Administrative Location';
        }

        field(72; "Is Invoice Destination"; Boolean)
        {
            Caption = 'Is Invoice Destination';
        }

        field(73; "Is Delivery Location"; Boolean)
        {
            Caption = 'Is Delivery Location';
        }

        field(74; "Is Execution Location"; Boolean)
        {
            Caption = 'Is Execution Location';
        }

        field(75; "Is Meeting Location"; Boolean)
        {
            Caption = 'Is Meeting Location';
        }

        field(76; "Is Temporary Location"; Boolean)
        {
            Caption = 'Is Temporary Location';
        }

        // ---------------------------------------------------
        // OPERATIONAL
        // ---------------------------------------------------

        field(80; Capacity; Decimal)
        {
            Caption = 'Capacity';
        }

        field(81; "Default Duration"; Duration)
        {
            Caption = 'Default Duration';
        }

        field(82; "Requires Access Approval"; Boolean)
        {
            Caption = 'Requires Access Approval';
        }

        field(83; "Access Instructions"; Blob)
        {
            Caption = 'Access Instructions';
            SubType = Memo;
        }

        field(84; "Parking Available"; Boolean)
        {
            Caption = 'Parking Available';
        }

        field(85; "Warehouse Location Code"; Code[20])
        {
            Caption = 'Warehouse Location Code';
            TableRelation = Location.Code;
        }

        // ---------------------------------------------------
        // GPS / MAPS
        // ---------------------------------------------------

        field(90; Latitude; Decimal)
        {
            Caption = 'Latitude';
            DecimalPlaces = 0 : 8;
        }

        field(91; Longitude; Decimal)
        {
            Caption = 'Longitude';
            DecimalPlaces = 0 : 8;
        }

        field(92; "Navigation URL"; Text[250])
        {
            Caption = 'Navigation URL';
        }

        field(93; "Geofence Radius (m)"; Decimal)
        {
            Caption = 'Geofence Radius (m)';
        }

        // ---------------------------------------------------
        // PLANNING
        // ---------------------------------------------------

        field(100; "Default Resource No."; Code[20])
        {
            Caption = 'Default Resource No.';
            TableRelation = Resource."No.";
        }

        field(101; "Preferred Vendor No."; Code[20])
        {
            Caption = 'Preferred Vendor No.';
            TableRelation = Vendor."No.";
        }

        field(102; "Planning Priority"; Integer)
        {
            Caption = 'Planning Priority';
        }

        field(103; "Time Zone"; Text[50])
        {
            Caption = 'Time Zone';
        }

        // ---------------------------------------------------
        // SYSTEM
        // ---------------------------------------------------

        field(200; "Created Date Time"; DateTime)
        {
            Caption = 'Created Date Time';
            Editable = false;
        }

        field(201; "Created By User"; Code[50])
        {
            Caption = 'Created By User';
            Editable = false;
        }

        field(202; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }

        field(203; "Last Modified By User"; Code[50])
        {
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