/*
* @why  : The test factory is all about creating the test data setup for all the business objects which are
*       used inside the code
* @when : CreatedDate : 06-AUG-2018
* @what : The test factory is all about creating the test data setup for all the business objects which are
*       used inside the code.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    06-AUG-2018            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit            Removed commented code. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman             03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D11_Concomitant_Null__c to CMPL123CME__D10_Concomitant_Product_Null__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Sameer               09-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G3_Report_Source__c to CMPL123CME__G2_Report_Source__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Sameer               09-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G3_Report_Source_Other__c to CMPL123CME__G2_Other_Report_Source__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TestDataFactory {

    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        SObject retObject = createSObject(sObj);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject createSObject(SObject sObj) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        String defaultClassName = 'TestDataFactory.' + objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
        // If there is a class that exists for the default values, then use them
        if (Type.forName(defaultClassName) != null) {
            sObj = createSObject(sObj, defaultClassName);
        }
        return sObj;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName) {
        // Create an instance of the defaults class so we can get the Map of field defaults
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            Throw new TestDataFactoryException(System.label.General_Test_Data_Exception);
        }
        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());
        return sObj;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
        SObject retObject = createSObject(sObj, defaultClassName);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject[] createSObjectList(List<SObject> objs, Boolean doInsert) {

        if (doInsert) {
            insert objs;
        }
        return objs;
    }

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        // Loop through the map of fields and if they weren't specifically assigned, fill them.
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();

        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }


    // Update SObject
    public static SObject updateSObject(SObject sObj) {
        update sObj;
        return sObj;
    }

    // Delete SObject
    public static void deleteSObject(SObject sObj) {
        delete sObj;
    }

    public class TestDataFactoryException extends Exception {}

    // Use the FieldDefaults interface to set up values you want to default in for all objects.
    public Interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }

    // Default data for Country
    public class CountryDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Country__c.Name => 'USA',
                Country__c.Country_Code__c => 'CA',
                Country__c.Language__c => 'English',
                Country__c.Division__c => 'ADD'
            };
        }
    }

    //Default data for CountrySubmissionType
    public class CountrySubmissionTypeDefaults implements FieldDefaults{
         public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Country_Submission_Type__c.Name => '30 Days',
                Country_Submission_Type__c.Calendar_Days__c => 30
            };
        }
    }

    //Default data for MeaningData Request
    public class Meaningful_Data_RequestDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Meaningful_Data_Request__c.Request_Type__c => 'Customer Request',
                Meaningful_Data_Request__c.Question_Action__c => 'Test Questions'
            };
        }
    }

     //Default data for EMDR Integration Request
    public class EMDR_IntegrationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Account
    public class AccountDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Account.Name => 'Abbott Aspen',
                Account.ShippingStreet => '86 Abraham Bay Winnipeg',
                Account.ShippingCity => 'Manitoba',
                Account.ShippingState => 'Winnipeg',
                Account.ShippingPostalCode => '12345-6789',
                Account.ShippingCountry => 'CANADA',
                Account.Phone => '9876543210',
                Account.CMPL123__Account_Email__c => 'abbott@aspen.com' ,
                Account.Fax => '9876543210'
            };
        }
    }

    //Default data for Ticket Product Evaluation Investigation
    public class TicketProductEvaluationInvestigationDefaults implements FieldDefaults{
       public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Contact
    public class ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Contact.FirstName => 'Robert',
                Contact.LastName => 'Cage',
                Contact.Salutation => 'Mr.'
            };
        }
    }

    // Default data for Translation Task
    public class Translation_TaskDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Translation Item
    public class Translation_ItemDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Translation Vendor
    public class Translation_VendorDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for FeedItem
    public class FeedItemDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for FeedComment
    public class FeedCommentDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for HHE
    public class CMPL123CMEHHEDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Questionnaire
    public class CMPL123CMEComplaint_InvestigationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Questionnaire
    public class CMPL123CMEQuestionnaireDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Questionnaire Items
    public class CMPL123CMEQuestionnaire_ItemsDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                CMPL123CME__Questionnaire_Items__c.CMPL123CME__Decision_Level__c => '1.0'
            };
        }
    }

    // Default data for TGA
    public class CMPL123CMETGADefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                // need to do
            };
        }
    }

    // Default data for CVR
    public class CMPL123CMECVRDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                CMPL123CME__CVR__c.CMPL123CME__Type_of_Report__c => 'Preliminary',
                CMPL123CME__CVR__c.CMPL123CME__Date_Submitted__c => System.today()
            };
        }
    }

    // Default data for MEDDEV
    public class CMPL123CMEMEDDEVDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                // need to do
            };
        }
    }
    // Default data for MDR
    public class CMPL123CMEMDRDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                // need to do
            };
        }
    }

    // Default data for EUMIR
    public class CMPL123CMEEUMIRDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                // need to do
            };
        }
    }

    /**
     * Default data for EMDR
     * @revision: 21-FEB-2023 Larry: Added defaults for E1 - Phone, G1 - Contact Office Email,
     * and G1 - Contact Office Phone Number. They are now required by the FDA.
     * The phone numbers are defaulted to non-USA values.
     */
    public class CMPL123CMEEMDRDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                CMPL123CME__EMDR__c.CMPL123CME__A1_Patient_Identifier__c => '162323-1-1',
                CMPL123CME__EMDR__c.CMPL123CME__CMPL123_WF_Status__c => 'Opened',
                CMPL123CME__EMDR__c.CMPL123CME__D10_Concomitant_Product_Null__c => 'NA',
                CMPL123CME__EMDR__c.CMPL123CME__E1_Phone__c => '+011()1234567890',
                CMPL123CME__EMDR__c.CMPL123CME__G1_Contact_Office_E_mail__c => '20feb2023@email.com',
                CMPL123CME__EMDR__c.CMPL123CME__G1_Contact_Office_Phone_Number__c => '+011()3334567890',
                CMPL123CME__EMDR__c.CMPL123CME__G2_Other_Report_Source__c => 'NA',
                CMPL123CME__EMDR__c.CMPL123CME__G2_Report_Source__c => 'Study'
            };
        }
    }

    //CMPL123CME__MDR_Code__c
    // Default data for EMDR
    public class CMPL123CMEEMDR_CodeDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                //CMPL123CME__MDR_Code__c.CMPL123CME__EMDR_MDR_CODE_TYPE__c => 'DEVICE CODE',
                CMPL123CME__MDR_Code__c.CMPL123CME__Category__c => 'Evaluation Code',
                CMPL123CME__MDR_Code__c.CMPL123CME__EMDR_MDR_CODE_DESCRIPTION__c => 'Issues associated with the combustion of device components, resulting in any of the following: light, flame, smoke.',
                CMPL123CME__MDR_Code__c.CMPL123CME__EMDR_MDR_CODE_SECONDARY__c => 'A270300'                
            };
        }
    }

    // Default data for Registered Site
    public class CMPL123CMERegistered_SiteDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Facility_Name__c => 'Abbott Vascular International BVBA',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_First_Name__c => 'John',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Last_Name__c => 'Smith',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Address_1__c => '1 Broadway',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Address_2__c => '',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Postal_Code__c  => '10022',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_City__c => 'New York',
                CMPL123CME__Registered_Site__c.CMPL123CME__G2_Contact_Office_Phone_Number__c => '212-555-1234',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Fax_Number__c => '212-555-9876',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_E_mail__c => 'jsmith@test.com',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Country__c => 'USA',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Zip_Code__c => '5600',
                CMPL123CME__Registered_Site__c.CMPL123CME__Sequence_No__c => '00001',
                CMPL123CME__Registered_Site__c.CMPL123CME__Assigned_No__c => '123456',
                CMPL123CME__Registered_Site__c.CMPL123CME__Site_Name__c => 'AVECHO',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Facility_Name__c => 'Abbott Vascular',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Region_State__c => 'CA',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Division_Name__c => 'Abbott Vascular',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Zip_Code_Extension__c => '0703',
                CMPL123CME__Registered_Site__c.CMPL123CME__G1_Contact_Office_Title__c => 'Mr.'
            };
        }
    }

    // Default data for Product Segment
    public class Product_SegmentDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Lot/Device
    public class CMPL123DeviceDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                CMPL123__Device__c.CMPL123__Lot_Number__c =>  '12345',
                CMPL123__Device__c.Name => 'DEV-123'
            };
        }
    }

    // Default data for Investigation_Items
    public class CMPL123CMEInvestigation_ItemsDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default Date for Pre investigation
    public class PreInvestigationTaskDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Engineering Coding
    public class Engineering_CodingDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Submission History
    public class CMPL123CMESubmission_HistoryDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                CMPL123CME__Submission_History__c.CMPL123CME__Source__c => 'FDA',
                CMPL123CME__Submission_History__c.CMPL123CME__Status__c => 'Passed',
                CMPL123CME__Submission_History__c.CMPL123CME__Message_Id__c => '&lt;AS2.17.BizLink&gt'
            };
        }
    }

    // Default data for Letter Request
    public class Letter_RequestDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Custom Attachment
    public class AttachmentDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Related Investigation
    public class Related_InvestigationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Related Complaint
    public class Related_ComplaintsDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Potential Quality Issue
    public class Potential_Quality_IssueDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }
    // Default data for Method Code
    public class Method_CodeDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for RAM Review
    public class RAM_ReviewDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for CollaborationGroupRecord
    public class CollaborationGroupRecordDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for 123 Contact
    public class CMPL123ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }
    // Default data for 123 Address
    public class CMPL123AddressDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for 123 Repair
    public class CMPL123CMERepairDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for TopicAssignment
    public class TopicAssignmentDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }
    // Default data for Topic
    public class TopicDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Concomitant product
    public class CMPL123CMEConcomitant_ProductDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Inservice Request
    public class Inservice_RequestDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Journal
    public class JournalDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Assessment Admin
    public class CMPL123CMEQuestions_TemplateDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                CMPL123CME__Questions_Template__c.Name => 'Vigilance Assessment',
                CMPL123CME__Questions_Template__c.CMPL123CME__Key_Value__c => 'Vigilance_Tree',
                CMPL123CME__Questions_Template__c.CMPL123CME__Assessment_Version__c => 1,
                CMPL123CME__Questions_Template__c.CMPL123CME__Assessment_Status__c => 'Effective'
            };
        }
    }

    // Default data for Assessment Admin Item
    public class CMPL123CMEQuestions_Template_ItemDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                CMPL123CME__Questions_Template_Item__c.CMPL123CME__Question_No__c => 1,
                CMPL123CME__Questions_Template_Item__c.CMPL123CME__Weight__c => 0
            };
        }
    }

    /*123 Digital workflow setup */
    // Default data for 123 Workflow
    public class CMPL123WF_RuleDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for 123 Workflow Action
    public class CMPL123WF_ActionDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for 123 Workflow Status
    public class CMPL123WF_StatusDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for 123 Workflow Step
    public class CMPL123WF_StepDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    //Default data for TGA(TrackWise Digital Complaints)
    public class CMPL123WF_TGADefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{CMPL123CME__TGA__c.CMPL123CME__Report_Type__c => 'Initial' };
        }
    }
    /*123 Digital workflow setup  ends here*/

    /*------------Aspen Data Starts here----------------------*/
    // Default data for Product Evaluation/Investigation
    public class CMPL123CMEInvestigationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Product Evaluation Investigation
    public class Product_Evaluation_InvestigationtDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Product Lot
    public class Product_LottDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Product Ticket
    public class Product_TicketDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Evaluation/Investigation Task(Task__c)
    public class TaskDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Patient_Information__c
    public class Patient_InformationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Return__c
    public class ReturnDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Ticket__c
    public class TicketDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Complaint
    public class CMPL123CMEComplaintDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                CMPL123CME__Complaint__c.CMPL123CME__CMPL123_WF_Status__c => 'Opened'
            };
        }
    }

    // Default data for Regulatory_Task__c
    public class Regulatory_TaskDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Search__c
    public class SearchDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Ticket_Review__c
    public class Ticket_ReviewDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for User
    public class UserDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                User.Belongs_to_Text__c => 'META1;PEA2;PEI3;PEA4;TA5;TA6;CRA7;CRA8;TIMRA9;TRE9;Tran10;ME11;RTC12;RM13;HA14;RA14;AT15;RA16;TT17;META18;RM20;RM21;RM22;RM23;RM24;RM25;RM26;RM27;RM28;RM29;RM30;RM-HoQ;RM-HoM;RM-HoR;RM-HoT;HA31;IN-RA1;IN-TA1;CRQA'
            };
        }
    }

    //Default data for PermissionSetAssignment
    public class PermissionSetAssignmentDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Customer_Response__c
    public class Customer_ResponseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for UserRole
    public class UserRoleDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }
    //Default data for Profile
    public class ProfileDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Country_Backup_Vigilance_Contact__c
    public class  Country_Backup_Vigilance_ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Ticket_Product_Evaluation_Investigation__c
    public class  Ticket_Product_Evaluation_InvestigationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Ticket Notes
    public class  TicketNotesDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Hazard_Assessment__c
    public class  Hazard_AssessmentDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Meaningful_Data__c
    public class Meaningful_DataDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for TSB__c
    public class TSBDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                TSB__c.Name => 'TestTSB123'
            };
        }
    }

    //Default data for Trend_Item__c
    public class Trend_ItemDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Trend_Item__c.Trend_Item_Type__c => 'Assay',
                Trend_Item__c.Trend_Item_Name__c => 'Test',
                Trend_Item__c.Trend_Item_Description__c => 'Test',
                //Trend_Item__c.Process__c => 'Ticket T/T',
                Trend_Item__c.Division__c => 'ADD'
            };
        }
    }

    //Default data for Trend_Item_Product__c
    public class Trend_Item_ProductDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Trend_Item_Trend_Bucket__c
    public class Trend_Item_Trend_BucketDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Tracking_Trending_Review_Task__c
    public class Tracking_Trending_Review_TaskDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }


    // Default data for 123C Product
    public class CMPL123ProductDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>();
        }
    }

    // Default data for Complaint Code
    public class CMPL123CMEComplaint_CodeDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                CMPL123CME__Complaint_Code__c.CMPL123CME__Type__c  => 'TREND BUCKET CODE',
                CMPL123CME__Complaint_Code__c.Name => 'QREQ'
            };
        }
    }

    // Default data for Translation_Item__c
    public class TranslationItemDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Translation_Item__c.Name => 'Translation_Item'
            };
        }
    }

    // Default data for Trend_Item_Maintenance_Request__c
    public class Trend_Item_Maintenance_RequestDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for RMF__c
    public class RMFDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Medical_Evaluation_Task__c
    public class Medical_Evaluation_TaskDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for RCML_Task_Product__c
    public class RCML_Task_ProductDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Activity__c
    public class ActivityDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Return_Form_Master__c
    public class Return_Form_MasterDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Post_Market_Risk_Assessment_Risk_Contr__c
    public class Post_Market_Risk_Assessment_Risk_ContrDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Re_Open_Justification__c
    public class Re_Open_JustificationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Ticket_Search_Result__c
    public class Ticket_Search_ResultDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for Group
     public class GroupDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for GroupMember
    public class GroupMemberDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Country_Group_Contact__c
    public class Country_Group_ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Task_Product_Evaluation_Investigation__c
    public class Task_Product_Evaluation_InvestigationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Pre Information
    public class pRE_InformationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Pre Question
    public class pRE_QuestionDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

       // Default data for medical evaluation
    public class CMPL123CME_QuestionnaireDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Trend Item Product
    public class TrendItemProductDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Ticket Note
    public class Ticket_NoteDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Regulatory Assessment
    public class Regulatory_AssessmentDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Action_Task
    public class Action_TaskDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Additional_Approval
    public class Additional_ApprovalDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Ticket_Version
    public class Ticket_VersionDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for KI_Log
    public class KI_LogDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Job
    public class CMPL123X123JobDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for Job
    public class TicketSearchResultDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }


    // Default data for AuditTrailEntry
    public class AuditTrailEntryDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for AuditTrailEntry
    public class CMPL123AuditTrail_ConfigDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    //Default data for MDC_Trigger
    public class MDCTriggerDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
             };
        }
    }

    //Default data for  MDC_Field_Mapping
    public class MDCFieldMappingDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }

    // Default data for AcknowledgementMapping
     public class AcknowledgementMappingDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            };
        }
    }
    /*-------------Aspen Data ends here--------------------*/

    /**
     * Factory method that makes Products with completely filled names
     * @author 06-OCT-2022 Larry Resnik
     * @revision R3.1, Larry: Moved from ADDProductTicketTriggerHandlerTest
     * so that ADDTicketUpdateAsyncTest can also use this factory
     */
    public static CMPL123__Product__c makeProductWithLongNames(Boolean alsoInsert) {
        Map<String, SObjectField> productFieldMap =
            SObjectType.CMPL123__Product__c.fields.getMap();
        Integer nameLen = productFieldMap.get('Name').getDescribe().getLength();
        Integer lotNumLen = productFieldMap.get('CMPL123__Lot_No__c').getDescribe().getLength();
        Integer listNumLen = productFieldMap.get('List_Number__c').getDescribe().getLength();
        String longName = '*'.repeat(nameLen);
        String longLotNum = '*'.repeat(lotNumLen);
        String longListNum = '*'.repeat(listNumLen);
        return (CMPL123__Product__c) createSObject(
            new CMPL123__Product__c(
                Name = longName,
                CMPL123__Lot_No__c = longLotNum,
                List_Number__c = longListNum,
                Reportable_Confirmed_Malfunction_Descrip__c = 'malfunction',
                List_Base__c = 'test123'
            ),
            alsoInsert
        );
    }
}