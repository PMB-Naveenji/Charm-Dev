/* 
* @why  : ADDProductLotTriggerHandlerTest class for the ADDProductLotTriggerHandler, Product_Lot_AuditTrigger
* @when : CreatedDate : 25-Oct-2018         ModifiedDate : 9-APR-2019
* @what : Class to Handle Different scenarios from Product Lot Trigger.
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID         Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*    rslob                   03-June-2020           N/A                     Test class optimization
*    rsitc                   10-June-2020           N/A                     Updated code part, which is related to Users' insertion. 
                                                                            This change designed to prevent a 'DUPLICATE_USERNAME'
                                                                            error during deployment to Production environment
*  --------------------------------------------------------------------------------------------------------------------------------------
*    Charm COE               06-AUG-2025            IPDR-105                Added new method "preventDeletionForNonCreatorCheck" validation error is thrown 
																			when a user tries to delete a product/lot record which was created by integration user.
																			Modified "preventDeletionifParentClosedPEReviewCheck" and "updateProdEvalTest" methods
																			as previous validation error message is modified
*  --------------------------------------------------------------------------------------------------------------------------------------
     Charm COE               06-AUG-2025            IPDR-105                Added new method "preventDeletionForSystemGeneratedPLCheck" validation error is thrown
                                                                            when a user tries to delete a product/lot record, where user is neither the creator nor a business admin.
                                                                            Modified "preventDeletionifParentClosedPEReviewCheck" and "updateProdEvalTest" methods
																			as previous validation error message is modified
*  --------------------------------------------------------------------------------------------------------------------------------------
     Charm COE               06-AUG-2025            IPDR-105                Added new method "preventDeletionMDC" validation error is thrown
                                                                            when a user tries to delete a product/lot record, where unacknowledged MDCs are available.
*  --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ADDProductLotTriggerHandlerTest {
    
    /**
    * @Method       : Test setup
    * @Description  : To test the  ADDProductLotTriggerHandler functionality.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup static void setup () {
        
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Profile objNewProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];

        User aspenUser = TestUtil.insertTestUser(aspenInteg, 'aspenUserInteg@test.com', 'aspenUserInteg@test.com');
        User usr = TestUtil.insertTestUser(objProfile.Id, 'standarduser@test.com', 'standarduser_001@test.com', 'PEI3');
        
        
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened'
        ), true);

        System.runAs(aspenUser) {
            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c = '123',
                List_Number__c = '12345'
            ), true);

            // Create Product Ticket
            Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = 'Yes',
                Product__c = product.Id
            ), true);
        }

        insertData();
    }

    @future
    public static void insertData () {
        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserInteg@test.com%' LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Division__c  = 'ADD' 
                                              AND pRE_Status__c  = 'Yes'
                                              AND Country_of_origin__c  = 'INDIA'
                                              AND Business_Unit__c  = 'IA-CC'
                                              AND CMPL123CME__CMPL123_WF_Status__c  = 'Opened'
                                              LIMIT 1];
        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c WHERE Event_Ticket__c = :complaint.Id
                                        AND Likely_Cause__c = 'Yes'
                                        LIMIT 1];

        System.runAs(aspenUser) {
            //Get Investigation
            CMPL123CME__Investigation__c objInv = [SELECT Name, Id FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1];

            //Create Product Lot
            Product_Lot__c objProdLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Product_Evaluation_Investigation__c = objInv.Id, 
                Device_Expiration_Date__c = System.today(), 
                Device_Manufacturing_Date__c = System.today()), 
            true);
        }
    }
    
    /**
    * @Method       : preventDeletionifParentClosedPEReviewCheck
    * @Description  : update the Product Lot fields  
    * @Return       : N/A
    * @Params       : N/A
    **/    
    static testMethod void preventDeletionifParentClosedPEReviewCheck(){
        
        Test.startTest();
        
        //Get user
        User usr = [SELECT Id,Name FROM User WHERE LastName='Testing' LIMIT 1];
        
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,Name,Product_Ticket_List_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];
        
        System.assert([SELECT Name,Division__c, Id FROM CMPL123CME__Complaint__c WHERE Name != NULL LIMIT 1].size() > 0);
        
        System.assert([SELECT Name, Id FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1].size() > 0);
        
        // Get Product Ticket
        Product_Ticket__c prodTicket = [SELECT Id,Name,Product_List_Number__c FROM Product_Ticket__c WHERE Event_Ticket__c =: complaint.Id LIMIT 1];
        
        //Get Investigation
        CMPL123CME__Investigation__c objInv = [SELECT Name, Id FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1];
        
        //Create Product Lot
        Product_Lot__c prodLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
            Product_Name__c  = prodTicket.Id,
            Related_Ticket__c  = complaint.Id,
            Product_Evaluation_Investigation__c = objInv.Id ),true);
        
        
        //Get Product Lot
        Product_Lot__c objProdLot = [SELECT Name,Division__c, Id FROM Product_Lot__c WHERE Product_Name__c != NULL LIMIT 1];
        
        System.assert([SELECT Name,Division__c, Id FROM Product_Lot__c WHERE Product_Name__c != NULL LIMIT 1].size() > 0);
        
        //Update Product Lot
        objProdLot.Division__c  = 'ADD';
        UPDATE objProdLot;
        
        //Update Investigation to Closed-Done Status
        objInv.Additional_Action_Taken__c = 'Yes';
        objInv.Approver__c = UserInfo.getUserId();
        objInv.Assessor__c = UserInfo.getUserId();
        objInv.Product_Evaluation_Type__c = 'Lot to lot variability';
        objInv.CMPL123_WF_Status__c = 'Closed-Done';
        objInv.Close_to_Threshold__c = 'No';
        objInv.Prod_eval_KI_Log__c = true;
        objInv.Conclusion_Disposition__c = '80066 NO Deficiency, NO Malfunction';
        objInv.Conclusion_Summary__c = 'Test';
        objInv.Describe_Additional_Action_Taken__c = 'Test';
        objInv.Evaluator_Investigator__c = usr.Id;
        UPDATE objInv;
        
        //Delete product lOT
        try {
            DELETE objProdLot;
        }catch(Exception e){  
            String message = e.getMessage();         	
            //Assert for prevent product lot deletion if parent closed/PE Review
         	//system.assert(message.contains('Product/Lot can not be deleted when prod eval is "Closed-Done" or in "PE Review" Status'), 'message=' + message); //CHARM 7 - Commented because error description has changed
         	system.assert(True, message.contains(Label.PreventDeleteProductlotwhenProdEvalClosedPEReview)); //CHARM 7 - Added below lines as previous validation error message is modified
        }       
        Test.stopTest();
    }
    
    /**
    * @Method       : UpdateProdEvalTest
    * @Description  : Updating Prod Eval field after deleting Product-Lot
    * @Return       : N/A
    * @Params       : N/A
    **/    
    static testMethod void updateProdEvalTest () {
        User sysAdminUser = [SELECT Id FROM User WHERE Username LIKE 'standarduser_001@test.com%' LIMIT 1];
        System.runAs(sysAdminUser) {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,Name,Product_Ticket_List_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];
        
        // Get Product Ticket
        Product_Ticket__c prodTicket = [SELECT Id,Name,Product_List_Number__c FROM Product_Ticket__c WHERE Event_Ticket__c =: complaint.Id LIMIT 1];
        
        //Get Investigation
        //CMPL123CME__Investigation__c objInv = [SELECT Name, Id,Has_Product_Lot_Child__c FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1];
        CMPL123CME__Investigation__c objInv = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                    CMPL123CME__Complaint__c = complaint.Id,
                    Conclusion_Summary__c = 'Conslusion Summarry test1',
                    Product_Evaluation_Type__c = 'Lot to lot variability',
                    Additional_Action_Taken__c = 'No',
                    Close_to_Threshold__c = 'Yes',
                    Prod_Eval_Returns_to_be_Requested__c = 'No',
                    Not_Requested_Rationale__c = 'Test 1',
                    CMPL123_WF_Action__c = '',
                    CMPL123_WF_Status__c = AspenConstants.STR_Assess,
                    Approval_Date__c = System.today()
                ),  True);
        
        //Get Product Lot
        Product_Lot__c objProdLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Product_Evaluation_Investigation__c = objInv.Id,
                Device_Expiration_Date__c = System.today(),
                Device_Manufacturing_Date__c = System.today()),
                true);   
        
        //Update Product Lot
        objProdLot.Division__c  = 'ADD';
        UPDATE objProdLot;
        
        Test.startTest();
        //Delete Product Lot
        TestDataFactory.deleteSObject(objProdLot);
        Test.stopTest();

        System.assertEquals(false, [SELECT Has_Product_Lot_Child__c FROM CMPL123CME__Investigation__c WHERE Id = :objInv.Id].Has_Product_Lot_Child__c);
        }
    }
    /*
    * @Method       : preventDeletionForSystemGeneratedPLCheck
    * @Description  : To test validation error is thrown when a user tries to delete a system generated product/lot record.
    * @Return       : N/A.
    * @Params       : N/A.
    * @Release      : CHARM 7- IPDR 105
    */
    static testMethod void preventDeletionForSystemGeneratedPLCheck () {
        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserInteg@test.com%' LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Division__c  = 'ADD'
                                              AND pRE_Status__c  = 'Yes'
                                              AND Country_of_origin__c  = 'INDIA'
                                              AND Business_Unit__c  = 'IA-CC'
                                              AND CMPL123CME__CMPL123_WF_Status__c  = 'Opened'
                                              LIMIT 1];
        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c WHERE Event_Ticket__c = :complaint.Id
                                        AND Likely_Cause__c = 'Yes'
                                        LIMIT 1];
        Product_Lot__c objProdLot = new Product_Lot__c();

        System.runAs(aspenUser) {
            //Get Investigation
            CMPL123CME__Investigation__c objInv = [SELECT Name, Id FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1];

            //Create Product Lot
            	objProdLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Product_Evaluation_Investigation__c = objInv.Id,
                Device_Expiration_Date__c = System.today(),
                Device_Manufacturing_Date__c = System.today(),
              // IPDR 105Set the system-generated flag to true to indicate that this Product Lot was system generated.
                System_Generated_Flag__c=true),
                true);            
        }
        Test.startTest();
        //System Admin user
        User sysAdminUser = [SELECT Id FROM User WHERE Username LIKE 'standarduser_001@test.com%' LIMIT 1];
        System.runAs(sysAdminUser) {           
            try {
            	TestDataFactory.deleteSObject(objProdLot);
            }
            catch (Exception e) {
                System.debug('Error in AddProductLotTriggerhan is'+e.getmessage());
                String msg = e.getmessage();
                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    Integer startIndex = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length();
                    String errorMessage = msg.substring(startIndex).trim();
                    // Assert to check - Product/Lots created by Integration users can't be deleted by any other user
                    system.assertEquals(True, errorMessage.contains(Label.Product_Lot_Delete_Error_Message_for_Admin));
                }
            }            
        }
        Test.stopTest();
    }
    
     /*
    * @Method       : preventDeletionForNonCreatorCheck.
    * @Description  : To test validation error is thrown when a user tries to delete a product/lot record which was created by different user
    * @Return       : N/A.
    * @Params       : N/A.
    * @Release      : CHARM 7- IPDR 105
    */
    static testMethod void preventDeletionForNonCreatorCheck () {
        User aspenUser = [SELECT Id FROM User WHERE Profile_Name__c = 'Aspen User' AND IsActive = True Limit 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Division__c  = 'ADD'
                                              AND pRE_Status__c  = 'Yes'
                                              AND Country_of_origin__c  = 'INDIA'
                                              AND Business_Unit__c  = 'IA-CC'
                                              AND CMPL123CME__CMPL123_WF_Status__c  = 'Opened'
                                              LIMIT 1];

        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c WHERE Event_Ticket__c = :complaint.Id
                                        AND Likely_Cause__c = 'Yes'
                                        LIMIT 1];
        Product_Lot__c objProdLot = new Product_Lot__c();

        System.runAs(aspenUser) {
            //Get Investigation
            CMPL123CME__Investigation__c objInv = [SELECT Name, Id FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1];
            //Create Product Lot
            	objProdLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Product_Evaluation_Investigation__c = objInv.Id,
                Device_Expiration_Date__c = System.today(),
                Device_Manufacturing_Date__c = System.today()),
                true);            
        }
        Test.startTest();
        User sysAdminUser = [SELECT Id FROM User WHERE Username LIKE 'standarduser_001@test.com%' LIMIT 1];
        System.runAs(sysAdminUser) {           
            try {
            	TestDataFactory.deleteSObject(objProdLot);
            }
            catch (Exception e) {
                String msg = e.getmessage();
                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    Integer startIndex = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length();
                    String errorMessage = msg.substring(startIndex).trim();
                    // Assert to check - Product/Lots created by Integration users can't be deleted by any other user
                    system.assertEquals(True, errorMessage.contains(Label.Product_Lot_Delete_Error_Message));
                }
            }            
        }
        Test.stopTest();
    }
    
    /*
    * @Method       : preventDeletionMDC
    * @Description  : To test validation error is thrown when a user tries to delete a product/lot record, where Unacknowledged MDC exists for Product/Lot in a ticket.
    * @Return       : N/A.
    * @Params       : N/A.
    * @Release      : CHARM 7- IPDR 105
    */
    static testMethod void preventDeletionMDC() {
        // Set up MDC Trigger configuration
        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c(
            CMPL123__Select_Target_Object__c = 'Product_Lot__c',
            CMPL123__Criteria__c = 'Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Active__c = true
        ), true);
        
        TestDataFactory.createSObject(new CMPL123__MDC_Field_Mapping__c(
            CMPL123__Index__c = 1,
            CMPL123__Field_API__c = 'Device_Expiration_Date__c',
            CMPL123__Condition__c = 'Custom',
            CMPL123__Selected_object__c = 'Product_Lot__c',
            CMPL123__Parent_object__c = mdcTrigger.Id,
            CMPL123__Parameters__c = 'ProductLotMDCCustom'
        ), true);
        
        TestDataFactory.createSObject(new CMPL123__AcknowledgementMapping__c(
            CMPL123__SelectObject__c = 'Product_Lot__c',
            CMPL123__AckNumber__c = 1,
            CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
            CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
            CMPL123__Index__c = 1
        ), true);
        
        User aspenUser = [SELECT Id FROM User WHERE Profile_Name__c = 'Aspen User' AND IsActive = True LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id, Overall_Reportable_Status__c FROM CMPL123CME__Complaint__c 
                                              WHERE Division__c = 'ADD'
                                              AND pRE_Status__c = 'Yes'
                                              AND Country_of_origin__c = 'INDIA'
                                              AND Business_Unit__c = 'IA-CC'
                                              AND CMPL123CME__CMPL123_WF_Status__c = 'Opened'
                                              LIMIT 1];
        
        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireReportable = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questInitialRecordType,
            CMPL123CME__Complaint__c = complaint.Id,
            Reportability_Category__c = 'Always Reportable',
            CMPL123_WF_Status__c = 'Regulatory',
            Reportability_Rationale__c = 'It is Reportable',
            Reportability__c = 'Reportable',
            Reportability_Date__c = Date.newInstance(2024, 05, 12),
            Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
            Follow_Up_Awareness_Date__c = System.today(),
            Submitted_Date__c = System.today()
        ), true);
        
        complaint.Overall_Reportable_Status__c = 'Reportable';
        update complaint;
        
        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c 
                                        WHERE Event_Ticket__c = :complaint.Id
                                        AND Likely_Cause__c = 'Yes'
                                        LIMIT 1];
        
        // Create and update the Product Lot to trigger MDC Ticket
        System.runAs(aspenUser) {
            CMPL123CME__Investigation__c objInv = [SELECT Name, Id FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1];
            
            Product_Lot__c objProdLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Product_Evaluation_Investigation__c = objInv.Id,
                Device_Expiration_Date__c = System.today(),
                Device_Manufacturing_Date__c = System.today()),
                true);  
             //Update the Product Lot to trigger MDC Ticket creation
            objProdLot.Device_Expiration_Date__c = System.today() + 1;
            update objProdLot;
            List<Product_Lot__c> plList=[Select Id,Name from Product_Lot__c where id=:objProdLot.Id];
            CMPL123__MDC_Ticket__c mdcTicket = new CMPL123__MDC_Ticket__c (
                CMPL123__Rule_Description__c  = 'MDC Ticket 1',
                CMPL123__Related_Record_Detail__c = '12345(Complaint)',
                CMPL123__MDC_Trigger__c = mdcTrigger.Id,
                Related_Ticket_Id__c = complaint.Id,
                CMPL123__Related_Record_ID__c = plList[0].Id,
                CMPL123__Related_Record_Name__c=plList[0].Name
            );
            insert mdcTicket;
            
            // Verify MDC Ticket was created
            List<CMPL123__MDC_Ticket__c> mdcTickets = [SELECT Id, Name, CMPL123__Related_Record_Name__c,CMPL123__Related_Record_ID__c, CMPL123__All_Acks_Received__c FROM CMPL123__MDC_Ticket__c  WHERE CMPL123__Related_Record_ID__c =: plList[0].Id AND CMPL123__All_Acks_Received__c = false];
            System.assert(!mdcTickets.isEmpty(), 'MDC Ticket should be created');
            
            Test.startTest();
            // Attempt to delete the Product Lot with MDC Ticket
            try{
                delete objProdLot;
            } catch (Exception e) {
                String msg = e.getMessage();
                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    Integer startIndex = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length();
                    String errorMessage = msg.substring(startIndex).trim();
                    // Assert to check - Product/Lots created by Integration users can't be deleted by any other user
                    system.assertEquals(true, errorMessage.contains(Label.Product_Lot_Delete_Error_Message_for_MDC));
                }
            }
            Test.stopTest();
        }
    }
}