/* 
* @why  : TicketServiceTest test class for the TicketServiceHandler class
* @when : CreatedDate : 12-Oct-2018         ModifiedDate : 22-Apr-2019
* @what : Class to Handle Different scenarios for TicketServiceHandler.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak    	             10-JUN-2020	        N/A                  Updated code part, which is related to Users' insertion.
*                                                                        This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                        deployment to Production environment
*  --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TicketServiceTest {  
/**
* @Method       : setupData
* @Description  : Create Test Data for TicketServiceHandler
**/
    @testSetup static void setupData() {
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;

        User ssTestUser = TestUtil.insertTestUser(aspenInteg, 'ssTestUser@test.com', 'ssTestUser@test.com');

        System.runAs(ssTestUser) {
            // Create Product record
            CMPL123__Product__c arcProduct = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    List_Number__c = '01DA2-08',
                    Name = 'ARC CI82 THINK INSTALL'
            ), true);

            // Create Product record
            CMPL123__Product__c asynProd = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    List_Number__c = '05960-51',
                    Name = '#212A MODEM ASYN'
            ), true);
        }
    }
    
    /**
    * @Method       : createOrUpdateTicketParent
    * @Description  : update Product Ticket fields  
    * @Return       : N/A
    * @Params       : N/A
    **/    
    @isTest
    public static  void testCreateOrUpdateTicket(){
        
        Test.startTest();  
        
        // Ticket Data recived from CMSNext
        StaticResource ticketData = [SELECT Id,Body FROM StaticResource WHERE Name ='TicketServiceData'];
        String ticketRecord = ticketData.Body.toString();
        
        //Setting up the mock callout for internal Ticket processor.
        Test.setMock(HttpCalloutMock.class, new TicketServiceProcessorMockRespTest());
        
        //Invoking createorUpdateTicket by providing the ticket data.
        TicketServiceWrapper.Ticket ticket = (TicketServiceWrapper.Ticket)JSON.deserialize(ticketRecord,TicketServiceWrapper.Ticket.class);
        TicketService.createOrUpdateTicket(ticket);  
        
        Test.stopTest();
        //Asserting ticket created.
        System.assertEquals(1,[SELECT COUNT() FROM CMPL123CME__Complaint__c]);
        System.assertEquals('159159C20181024',[SELECT CMSNext_Ticket_Id__c FROM CMPL123CME__Complaint__c].CMSNext_Ticket_Id__c);
        
    }
    
    /**
    * @Method       : createOrUpdateTicketParent
    * @Description  : update Product Ticket fields  
    * @Return       : N/A
    * @Params       : N/A
    **/    
    @isTest
    public static void testCreateOrUpdateTicketWithParent(){
        //Sample response provide by service processor
        StaticResource ticketWrapper = [SELECT Id,Body FROM StaticResource WHERE Name ='TicketSampleData' ];
        String ticketBody = ticketWrapper.Body.toString();
        
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl().toExternalForm()+'/services/apexrest/ASPEN/v1.0?type=parent'; //Request URL
        req.httpMethod = 'POST';
        req.addParameter('type', 'parent');
        req.requestBody = Blob.valueOf(ticketBody);
        RestContext.request = req;
        RestContext.response= res;
        
        //Invoking Processor class for creating of Ticket and other related childs.
        InternalTicketServiceProcessor.ResponseWrapper actual = InternalTicketServiceProcessor.insertChildRecords();//HttpClass.updateCustomObject();
        //Asserting the response recieved from Processor class
        System.assertEquals(true,actual.isSuccess);
    }
    
    
    /**
    * @Method       : createOrUpdateTicketParent
    * @Description  : update Product Ticket fields  
    * @Return       : N/A
    * @Params       : N/A
    **/    
    public static testMethod void createOrUpdateTicketWithoutParent(){
        //Sample response provide by service processor
        StaticResource ticketWrapper = [SELECT Id,Body FROM StaticResource WHERE Name ='TicketSampleData' ];
        String ticketBody = ticketWrapper.Body.toString();
       
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Url.getSalesforceBaseUrl().toExternalForm()+'/services/apexrest/ASPEN/v1.0?type=parent'; //Request URL
        req.httpMethod = 'POST';
        req.addParameter('type', '');
        req.requestBody = Blob.valueOf('{"Return__c~Return_Id__c":[{"attributes":{"type":"Return__c"},"Ticket__c":"","Version__c":"1","Return_Id__c":"CHaRM 24102018-01","Tracking_Website__c":"https://www.abbott.com","Tracking_Number__c":"3223","Return_not_Returned_Rationale__c":"Not working properly","Third_Return_Requested_Date__c":"2018-10-24T18:39:59.000+0000","Second_Return_Requested_Date__c":"2018-10-24T18:39:59.000+0000","Return_Requested_Date__c":"2018-10-24T18:39:59.000+0000","RMA__c":"43542","Product_Not_Returned_Rationale__c":"No Return Rationale"}],"Ticket_Note__c~Ticket_Notes_Created_ID__c":[{"attributes":{"type":"Ticket_Note__c"},"Ticket_Notes_Created_ID__c":"CHARM 24102018-01","Ticket_Notes_Created_Date__c":"2018-10-24T18:39:59.000+0000","Ticket_Notes_Created_By__c":"Amit","Ticket_Notes_Native__c":"QC OORL h6102 4.60 (5.07 +/- 0.30)  Customer using Cleaner lot 7110.  Performed Bleach, request service. TSS sending replacement Cleaner and Calibrator for ts.","Ticket__c":""}],"TSB__c~TSB_External_Id__c":[{"attributes":{"type":"TSB__c"},"Ticket__c":"","Name":"Testing TSB","TSB_Type__c":"TSB Type","TSB_External_ID__c":"CHaRM 24102018-01","TSB_Description__c":"No Description available for TSB","Activity_Type__c":"User Story Testing","TSB_Date__c":"2018-10-24T18:39:59.000+0000"},{"attributes":{"type":"TSB__c"},"Ticket__c":"","Name":"Testing TSB","TSB_Type__c":"Regulatary","TSB_External_ID__c":"CHaRM 24102018-02","TSB_Description__c":"No Description available for TSB","Activity_Type__c":"User Story Testing","TSB_Date__c":"2018-10-24T18:39:59.000+0000"}],"Patient_Information__c~External_Id__c":[{"attributes":{"type":"Patient_Information__c"},"Patient_Information__c":"Test Patient Information.","External_Id__c":"CHaRM 24102018-01","pRE_Information__c":""}],"pRE_Question__c~External_Id__c":[{"attributes":{"type":"pRE_Question__c"},"External_ID__c":"CHaRM 24102018-01","Ticket_Question_ID__c":"CHaRM Abbott 241018-01","Created_On__c":"2018-10-24T13:39:59Z","Last_Updated_On__c":"2018-10-24T13:39:59Z","Last_Updated_By__c":"Amit","Created_By__c":"Amit","Question_Type__c":"pRE_Guidelines","Answer__c":"Yes","Name":"NO User Report / Other Safety Issue","Question_Category_ID__c":"310","Question_Category__c":"pRE_Guidelines","pRE_Information__c":""},{"attributes":{"type":"pRE_Question__c"},"External_ID__c":"CHaRM 24102018-02","Ticket_Question_ID__c":"CHaRM Abbott 24102018-02","Created_On__c":"2018-10-24T13:39:59Z","Last_Updated_On__c":"2018-10-24T13:39:59Z","Last_Updated_By__c":"Amit","Created_By__c":"Amit","Question_Type__c":"pRE_Guidelines","Answer__c":"Yes","Name":"NO User Report","Question_Category_ID__c":"311","Question_Category__c":"pRE_Guidelines","pRE_Information__c":""}]}');
        //req.requestBody = Blob.valueOf(ticketBody);
        RestContext.request = req; 
        RestContext.response= res;
        
        //Invoking Processor class for creating of Ticket and other related childs.
        InternalTicketServiceProcessor.ResponseWrapper actual = InternalTicketServiceProcessor.insertChildRecords();//HttpClass.updateCustomObject();
        //Invoking Processor class for creating of Ticket and other related childs.
       // System.assertEquals(True,actual.isSuccess);
    }
    
    
    /**
    * @Method       : getResponse
    * @Description  : to get the response
    * @Return       : String
    * @Params       : N/A
    **/
    public static testMethod String getResponse(){
        InternalTicketServiceProcessor.ResponseWrapper response = new InternalTicketServiceProcessor.ResponseWrapper();
        
        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            CMSNext_Ticket_Id__c = 'ticket1234'
        ), true);    
        
        // Create pRE Information
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(new pRE_Information__c(
            External_ID__c = 'pre1234'
        ), true);    
        
        Account acc = new Account();
        acc.Customer_External_ID__c = 'acc1234';
        acc.Name = 'Test';
        
        upsert complaint;
        upsert preInfo;
        upsert acc;
        
        response.isSuccess = true;
        response.successMap = new Map<String,String>();
        response.successMap.put('accId',acc.Id);
        response.successMap.put('ticketId',complaint.Id);
        response.successMap.put('preInfoId',preInfo.Id);
        
        return JSON.serialize(response);
    }
    
     public static testMethod void validateVersion(){
        User ssTestUser = [SELECT Id, Username, Profile_Name__c FROM User WHERE Username LIKE '%ssTestUser@test.com%'][0];
        System.runAs(ssTestUser) {
            // Create Product record
            CMPL123__Product__c prod1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    CMPL123__Lot_No__c = '1234',
                    List_Number__c = '0AM16-40'
            ), true);

            // Create Product record
            CMPL123__Product__c prod2 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '03L77-01'
            ), true);
        }
         
        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            CMSNext_Ticket_Id__c = '159159C20181024',Ticket_Version__c = '6'
        ), true);   
        Test.startTest();
        
        // Ticket Data recived from CMSNext
        StaticResource ticketData = [SELECT Id,Body FROM StaticResource WHERE Name ='TicketServiceData'];
        String ticketRecord = ticketData.Body.toString();
        
        //Setting up the mock callout for internal Ticket processor.
        Test.setMock(HttpCalloutMock.class, new TicketServiceProcessorMockRespTest());
        
        //Invoking createorUpdateTicket by providing the ticket data.
        TicketServiceWrapper.Ticket ticket = (TicketServiceWrapper.Ticket)JSON.deserialize(ticketRecord,TicketServiceWrapper.Ticket.class);
        TicketService.createOrUpdateTicket(ticket);  
        TicketService.validateVersion(ticket);
        Test.stopTest();
    }
    
    public static testMethod void createTicketWithoutMDC(){
        testCreateOrUpdateTicketWithParent();
        	CMPL123CME__Complaint__c tkt = [Select Id from 	CMPL123CME__Complaint__c LIMIT 1];
        Id tktId = tkt.Id;
        //Sample response provide by service processor
        //StaticResource ticketWrapper = [SELECT Id,Body FROM StaticResource WHERE Name ='TicketSampleData' ];
        //String ticketBody = ticketWrapper.Body.toString();
       
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req1 = new RestRequest();
        RestResponse res1 = new RestResponse();
        req1.requestURI = System.Url.getSalesforceBaseUrl().toExternalForm()+'/services/apexrest/ASPEN/v1.0?type=parent'; //Request URL
        req1.httpMethod = 'POST';
        req1.addParameter('type', '');
        req1.requestBody = Blob.valueOf('{"Ticket_Note__c~Ticket_Notes_Created_ID__c":[{"attributes":{"type":"Ticket_Note__c"},"Ticket_Notes_Created_ID__c":"CHARM 24102018-01","Ticket_Notes_Created_Date__c":"2018-10-24T18:39:59.000+0000","Ticket_Notes_Created_By__c":"Amit","Ticket_Notes_Native__c":"QC OORL h6102 4.60 (5.07 +/- 0.30)  Customer using Cleaner lot 7110.  Performed Bleach, request service. TSS sending replacement Cleaner and Calibrator for ts.","Ticket__c":"'+tktId+'"}],"Meaningful_Data__c~Meaningful_Data_ID__c":[{"attributes":{"type":"Meaningful_Data__c"},"Meaningful_Data_Created_Date__c":"2026-05-19T12:24:44.000+0000","Meaningful_Data_Request_Progress__c":null,"Last_Modified_By__c":"RHX8","Last_Modified_On__c":"2026-05-19T12:24:44.000+0000","Meaningful_Data_Created_By__c":"RHX8","Meaningful_Data_Answers__c":"Customer has other working Abbott product","Mean__c":"What is the customer’s ability to process patient samples?","Meaningful_Data_Category__c":"All, INSTRUMENT","Meaningful_Data_ID__c":"5c8b47b7-7d53-f111-91bb-bb27b196b24d","Compliant__c":"'+tktId+'"}]}');
        //req.requestBody = Blob.valueOf(ticketBody);
        RestContext.request = req1; 
        RestContext.response= res1;
        
        //Invoking Processor class for creating of Ticket and other related childs.
        InternalTicketServiceProcessor.ResponseWrapper actual = InternalTicketServiceProcessor.insertChildRecords();//HttpClass.updateCustomObject();
        //Invoking Processor class for creating of Ticket and other related childs.
       // System.assertEquals(True,actual.isSuccess);
    }
}