/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Capgemini
* @What  : ContentDocumentEUMIRTriggerHandlerTest
* @Why   : Test class to manage all the custom coding invoked on the ContentDocument object..
* @When  : 11-AUG-2021
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID                         Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Varsha Hariharan        11-Aug-2021            CHaRM Release 2                           Created. 
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class ContentDocumentEUMIRTriggerHandlerTest {
    @isTest static void ContentDocTestMethod(){
             Id AspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
       User newUser1 = new User(ProfileId = AspenUserProfileId, LastName = 'admin1', Email = 'test0@0te0st.com',
                Username = 'test0@0te0st.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'TEST', Title = 'test', Alias = 'test', TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
        insert newUser1;
        User newUser2 = new User(ProfileId = AspenUserProfileId, LastName = 'admin2', Email = 'test1@1te1st.com',
                Username = 'test1@1te1st.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'TEST', Title = 'test', Alias = 'test', TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
        insert newUser2;
       User objUserMainContact = [SELECT Id FROM User WHERE LastName = 'admin1' LIMIT 1];
       User objUserBackupContact = [SELECT Id FROM User WHERE LastName = 'admin2' LIMIT 1];
        
        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Primary_Vigilance_Contact__c = objUserBackupContact.id), true);
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                    Name = '30 Days', Calendar_Days__c = 30,
                    Country__c = objCountry.Id
            ), true);
        //Create Country - Backup Vigilance Contact
        Country_Backup_Vigilance_Contact__c vigilanceCountryContact = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = objUserBackupContact.id,
                                                                                                                                                                                  Country__c = objCountry.id), true);
        
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId,
            Country_of_origin__c = 'USA'), true);
        
        List< Regulatory_Task__c > newRegTasks = new List< Regulatory_Task__c>();
        //CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(CMPL123_WF_Status__c = 'Regulatory',Reportability_Rationale__c = 'Test',Reportability__c = 'Non-Reportable',Reportability_Category__c = 'Adverse Event'), true);
        
        // Create Assessment 
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = assmntRTId,
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123_WF_Status__c = 'Regulatory',
            Reportability_Rationale__c = 'Regulatory',
            Reportability__c = 'Reportable',
            Reportability_Category__c = 'Always Reportable',
            Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
        ), true);
        CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) 
                TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    CMPL123CME__Site_Name__c = 'Test Registered Site',
                    Division__c = 'ADD'),
                false
            );        
        User user2 = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id,
                LastName = 'test2',
                Email = 'test2@gmail.com',
                Username = 'test2@gmail.com' + System.currentTimeMillis(),
                CompanyName = 'TEST2',
                Title = 'title2',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10'
        ), true);
        CMPL123CME__Registered_Site__c ivdrRegisteredSite = (CMPL123CME__Registered_Site__c) 
                TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    CMPL123CME__Site_Name__c = 'Test IVDR Site',
                    Division__c = 'ADD'),
                true
            );
        // Create Product
        CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    Name = 'ARC I2000SR INST',
                    CMPL123__Product_Code__c = '116',
                    CMPL123__Product_Family__c = 'ARCHITECT',
                    Device_Class__c = 'IVD General',
                    Device_Nomenclature_Code__c = '56701',
                    Device_Nomenclature_System__c = 'GMDN',
                    Device_Nomenclature_Text__c = 'Chemiluminescent immunoassay analyser IVD, automated',
                    Division__c = 'ADD',
                    External_ID__c = '03M74-02-ARCHITECT i2000SR',
                    FDA_Product_Code__c = 'JJE',
                    Instrument_Name__c = 'ARCHITECT i2000SR',
                    List_Number__c = '03M74-02',
                    Manufacturing_Location__c = 'Flextronics',
                    Notified_Body_ID__c = 'UL-INT.0843',
                    Product_Brand_Name__c = 'ARCHITECT i2000SR Analyzer',
                    Product_Classification__c = 'Device',
                    Product_Common_Name__c = 'Automated Immunoassay Analyzer',
                    Product_GTIN__c = '00380740006235',
                    Product_Subtype__c = 'INSTRUMENT',
                    Record_Rev__c = '4',
                    Record_Status__c = 'Active',
                    Reportable_Confirmed_MalfunctionInitDate__c = System.now(),
                    Reportable_Confirmed_Malfunction_Comment__c = 'test',
                    Reportable_Confirmed_Malfunction_Descrip__c = 'testing566',
                    Reportable_Confirmed_Malfunction_List__c = 'TRUE',
                    TODS_Product_Header_SeqNum__c = '1081000',
                    TPM_Product_Type__c = 'B',
                    TPM_Supplier_Name__c = 'Flextronics',
                    Type__c = 'INSTRUMENT',
                    X510K_Number__c = 'K983212',
                    Registered_Site__c = registeredSite.Id,
                    List_Base__c = 'TEST01',
                    Business_Unit__c = 'Professional Services',
                    Evaluation_Location__c = 'WI-TRANSFUSION',
                    IVDR_Notified_Body_NB_ID_1__c = '843',
                    IVDR_Registered_Site__c = ivdrRegisteredSite.Id
            ), true);
        
        //System.runas(user2) {
        
        //Create Product ticket
        Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
            Product__c = product.Id,
            Event_Ticket__c = complaint.Id,
            Batch_Lot_Serial__c = '1235'
        ), true);
        //}
        Date tod = System.today();
        Datetime now = System.now();
        final String MED_EVAL_EMAIL = 'medeval@test.com';
        final String PROFILE_USER = 'Aspen User';
        Map<String, Id> profileNameToId = new Map<String, Id>();
        final String PROFILE_SYSADMIN = 'System Administrator Data Loader';
        for (Profile prof : [
            SELECT Id, Name FROM Profile 
            WHERE Name IN :new String[]{PROFILE_SYSADMIN, PROFILE_USER}
        ]) {
            profileNameToId.put(prof.Name, prof.Id);
        }
        User medEvalUser = TestUtil.insertTestUser(profileNameToId.get(PROFILE_USER),
                MED_EVAL_EMAIL, 'test3@gmail.com' + System.currentTimeMillis(), 'Tran11');
        User medEvalUser2 = [SELECT Id, Email FROM User WHERE Email =: MED_EVAL_EMAIL LIMIT 1];
        test.startTest();
            CMPL123CME__EU_MIR__c eas=new CMPL123CME__EU_MIR__c(
            CMPL123CME__Basic_UDI_DI__c = 'Unknown',
            CMPL123CME__Basis_Of_Identifying_Similar_Events__c = 'Other',
            CMPL123CME__Catalogue_Reference_Number__c = '04R13-01',
            CMPL123CME__Classification_Of_Incident__c = 'Death',
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123CME__Current_Device_Location__c = 'Healthcare facility/carer',
            CMPL123CME__Date_Of_Incident_From__c = tod,
            CMPL123CME__Date_Of_Incident_To__c = tod,
            CMPL123CME__Date_Of_Submission__c = tod,
            CMPL123CME__Description_Of_Device_Nomenclature_Text__c = 'Description of device/Nomenclature textt',
            CMPL123CME__Description_Of_Remedial_Action__c = 'N/A',
            CMPL123CME__Device_Operator_At_Event__c = 'Healthcare professional',
            CMPL123CME__Device_Usage__c = 'Reuse of a reusable medical device',
            CMPL123CME__EUDAMED_Number_Of_NCA__c = 'NA',
            CMPL123CME__Expected_Date_Of_Next_Report__c = tod.addMonths(2),
            CMPL123CME__IVDD_Class__c = '',
            CMPL123CME__Incident_Description__c = 'Incident Descriptionn',
            CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c = 'N/A',
            CMPL123CME__Initial_Reporter_City_Name__c = 'São Paulo',
            CMPL123CME__Initial_Reporter_Contact_Last_Name__c = 'Latulia Gomes de Oliveira',
            CMPL123CME__Initial_Reporter_Country__c = 'Brazil',
            CMPL123CME__Initial_Reporter_Email__c = 'latulia.gomes@hc.fm.usp.br',
            CMPL123CME__Initial_Reporter_Phone__c = '11 26616919/26616918',
            CMPL123CME__Initial_Reporter_Postcode__c = '05403-010',
            CMPL123CME__Initial_Reporter_Street__c = 'R. Dr. Ovidio Pires de Campos, 333 1 andar Cerqueira Cesar',
            CMPL123CME__List_Down_Further_Investigations__c = 'N/A',
            CMPL123CME__Lot_Batch_Numbers__c = '000109',
            CMPL123CME__Manufact_City_Name__c = 'manuf city',
            CMPL123CME__Manufact_Contact_First_Name__c = 'manuf first name',
            CMPL123CME__Manufact_Contact_Last_Name__c = 'manuf last name',
            CMPL123CME__Manufact_Country__c = 'Macau',
            CMPL123CME__Manufact_E_Mail__c = 'manuf@abbott.com',
            CMPL123CME__Manufact_Organisation_Name__c = 'Manuf Org.',
            CMPL123CME__Manufact_Phone__c = '12131415',
            CMPL123CME__Manufact_Postcode__c = '123456',
            CMPL123CME__Manufact_Street__c = 'street 11',
            CMPL123CME__Manufacturer_Awareness_Date__c = tod,
            CMPL123CME__Medical_Device_Name__c = 'med device',
            CMPL123CME__Model__c = 'N/A',
            CMPL123CME__Name_Of_The_Healthcare_Facility__c = 'HOSP CLIN FAC MED USP - IOT',
            CMPL123CME__Preliminary_Results_And_Conclusions__c = 'Preliminary Results and Conclusionss',
            CMPL123CME__Recipient_Name_Of_NCA__c = 'Agence nationale de sécurité du médicament et des produits de santé (ANSM)',
            CMPL123CME__Reference_Number_By_Manufacturer__c = '0211590C1522823',
            CMPL123CME__Reference_Number_By_NCA__c = 'Unknown',
            CMPL123CME__Registered_Commercial_Name_Of_Company__c = 'Reg.Commercial Name Co.',
            CMPL123CME__Relevant_Associated_Devices__c = 'CD-EMERALD 22 AL ANALYZ 04R13-01 000109',
            CMPL123CME__Role_Of_Initial_Reporter__c = 'Healthcare professional',
            CMPL123CME__Serial_Numbers__c = '000109',
            CMPL123CME__Specify_Other_Submitter__c = 'testing',
            CMPL123CME__Submitter_City_Name__c = 'Waukegan',
            CMPL123CME__Submitter_Contact_First_Name__c = 'add',
            CMPL123CME__Submitter_Contact_Last_Name__c = 'vigilance_contact2',
            CMPL123CME__Submitter_Country__c = 'Country',
            CMPL123CME__Submitter_E_Mail__c = 'charm-tech-support-val@abbott.com',
            CMPL123CME__Submitter_Of_Report__c = 'Others',
            CMPL123CME__Submitter_Phone__c = '2345651235',
            CMPL123CME__Submitter_Postcode__c = '60085',
            CMPL123CME__Submitter_Street__c = '500 Normal St',
            CMPL123CME__Type_Of_Report__c = 'Initial',
            CMPL123CME__UDI_DI__c = 'Unknown',
            CMPL123CME__UDI_PI__c = 'unknown',
            CMPL123CME__Unit_Of_Use_UDI_DI__c = 'unknown',
            CMPL123CME__A_Medical_Device_Problem_Code_Choice_1__c = 'A090803 - False Negative Result',
            CMPL123CME__E_Clinical_Signs_Symptoms_Code_Choice_1__c = 'E0116 - Headache',
            CMPL123CME__F_Health_Impact_Code_Choice_1__c = 'F02 - Death',
            CMPL123Task_Key_Value__c = '',
            CMPL123_WF_Action__c = '',
            CMPL123_WF_Status__c = 'Opened',
            CMPL123_WF_Action_Performed_On__c = now,
            CMPL123Rule_Key_Value__c = 'EU_MIR_WF',
            CMPL123_WF_Action_Performed_By__c = medEvalUser.Id,
            Action_on_Follow_Up_Awareness_Date__c = 'Set Date',
            Complete_Regulatory_Response_By__c = 'add medical_evaluator2',
            Complete_Regulatory_Response_Date__c = tod,
            Country__c = objCountry.Id,
            Date_Due__c = tod.addDays(10),
            Division__c = 'ADD',
            Follow_Up_Required__c = '',
            Last_Modified_Date_Time__c = now,
            MedicalEvaluation__c = questionnaireRecord.Id,
            Medical_Evaluator__c = medEvalUser.Id,
            Product_Type__c = 'IVDD/MDD',
            Product__c = prodTckt.Id,
            Registered_Site__c = registeredSite.Id,
            Report_Submitter__c = 'add medical_evaluator2',
            Submission_Type__c = objCountrySubmissionType.Id,
            Submit_to_Regulatory_By__c = 'add medical_evaluator2',
            Submit_to_Regulatory_Date__c = tod,
            Waived_Rationale__c = 'This issue does not need to be reported per local regulatory requirements',
            CMPL123CME__Device_Has_Been_Placed_On_Market_Before__c = 'This device has been placed on the market before the implementation of the MDD/AIMDD/IVDD ',
            // Medical_Device_Name__c = 'med dev name',
            New_Followup_Awareness_Date__c = tod
            );
                
            insert eas;
        test.stopTest();
                Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
                ContentVersion contentVersion_1 = new ContentVersion(
                Title='Header_Picture4', 
                PathOnClient ='/Header_Picture7.pdf',
                VersionData = bodyBlob, 
                origin = 'H'
                );
        insert contentVersion_1;
        Blob bodyBlob1=Blob.valueOf('Unit Test ContentVersion Body'); 
                ContentVersion contentVersion_3 = new ContentVersion(
                Title='Header_Picture9', 
                PathOnClient ='/Header_Picture8.pdf',
                VersionData = bodyBlob, 
                origin = 'H'
                );
                insert contentVersion_3;
                ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
                ContentVersion contentVersion_4 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_3.Id LIMIT 1];
                List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
                
                ContentWorkspace conwrk = [SELECT id,name FROM ContentWorkspace where name = :'Asset Library'];
                ContentWorkspaceDoc newDoc = new ContentWorkspaceDoc();
                ContentWorkspaceDoc newDoc1 = new ContentWorkspaceDoc();
                newDoc.ContentDocumentId = contentVersion_2.ContentDocumentId;
                newDoc.ContentWorkspaceId = conwrk.Id;
                insert newDoc;
                newDoc1.ContentDocumentId = contentVersion_4.ContentDocumentId;
                newDoc1.ContentWorkspaceId = conwrk.Id;
                insert newDoc1;
                List<ContentDocumentLink> newList = new List<ContentDocumentLink>();
                ContentDocumentLink filesObj = new ContentDocumentLink();
                filesObj.LinkedEntityId = eas.id;
                filesObj.contentdocumentid = newDoc.ContentDocumentId;
                filesObj.ShareType = 'V';
                filesObj.Visibility = 'AllUsers';   
                insert filesObj;  
        try {
            ContentDocumentLink filesObj1 = new ContentDocumentLink();
                filesObj1.LinkedEntityId = eas.id;
                filesObj1.contentdocumentid = newDoc1.ContentDocumentId;
                filesObj1.ShareType = 'V';
                filesObj1.Visibility = 'AllUsers';  
                insert filesObj1; 
        } catch (DMLException dmex) {
            System.assert(dmex.getMessage().contains('One file has already been uploaded for this record'));           
        }
    }
}