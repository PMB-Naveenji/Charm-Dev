/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) Capgemini.
* @What  : TicketReviewRecodErrorBatch.
* @Why   : This  class is used to get Failed Ticket Review Class.
* @When  : 20- July -2021.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                      Modification ID                Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid  				   20 July-2021				Work ID / Case ID                Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid  				   20 July-2021			    Ticket Review Devlopment        Added a Logic for Fail Ticket Reviews  
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             20 JUL 2024              CHaRM-R5/IPDR 191               Updated "finish" method
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class TicketReviewRecodErrorBatch implements Database.Batchable<sObject>,Database.stateful {
    global String labelValue = system.Label.Ticket_Review_Failed_Job_Duration;
    global  Set<Id> ticketReviewIdSet = new Set<Id>();
    global  Map<Id,String> userDataMap = new Map<Id,String>();
    
    
    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC) {  
        String jobStatus = 'Failed';
        DateTime dateObj = DateTime.now();
        if(labelValue.contains(':')){
            
            Integer index = labelValue.indexOf(':');
            Integer hours = Integer.valueOf(labelValue.substring(0,index));
            Integer minutes = Integer.valueOf(labelValue.substring(index+1,labelValue.length()));
            if(hours != 0){
                hours = -hours;
                dateObj = dateObj.addHours(hours);   
            }
            
            if(minutes != 0){
                minutes = -minutes;
                dateObj = dateObj.addMinutes(minutes); 
            }
            
        }else{
            Integer hours = - Integer.valueOf(labelValue);
            dateObj = dateObj.addHours(hours); 
            
        }
        String query = 'SELECT Id, Status, CreatedById, completedDate FROM AsyncApexJob where status = : jobStatus And completedDate > : dateObj';
     
        return Database.getQueryLocator(query); 
    }
    // Execute method
    global void execute(Database.BatchableContext BC, List<AsyncApexJob> asyncFailedJobList){
       
        Set<Id> asyncFailedJobIdSet = new Set<Id>();
        Map<Id,DateTime> asyncJobIdCompetedDateMap = new Map<Id,DateTime>();
        for(AsyncApexJob asyncObject: asyncFailedJobList){
            asyncFailedJobIdSet.add(asyncObject.Id); 
            asyncJobIdCompetedDateMap.put(asyncObject.Id,asyncObject.CompletedDate);
            
        }
        Map<Id,Ticket_review__c> ticketReviewMap = new Map<Id,Ticket_review__c>([SELECT Id, Name, Quality_Assignee_Name__r.Name,Quality_Assignee_Name__r.Email,
                                                      Medical_Assignee_Name__r.Name,medical_Assignee_Name__r.Email,RecordType.Name,Search_Frequency__c,Pending_Batch_Jobs__c 
                                                                                 FROM Ticket_Review__c 
                                                                                 WHERE RecordTypeId =: AspenConstants.Recurrence_Search_RecordType_Id AND Pending_Batch_Jobs__c IN : asyncFailedJobIdSet]);
        
        
        for(Ticket_review__c tickedObject: ticketReviewMap.values()){
            ticketReviewIdSet.add(tickedObject.Id);
        }
        
        
        String fileRow = '';
   
        for(Ticket_review__c ticketObject: ticketReviewMap.values()){
        
			DateTime competedDate = asyncJobIdCompetedDateMap.get(ticketObject.Pending_Batch_Jobs__c) != Null ? asyncJobIdCompetedDateMap.get(ticketObject.Pending_Batch_Jobs__c) : System.now() ;
           	
            String medicalAssigneeName = 'N/A';
            if(ticketObject.Medical_Assignee_Name__r.Name != null){
                medicalAssigneeName = ticketObject.Medical_Assignee_Name__r.Name;
            }
            fileRow = '';
            fileRow = fileRow +','+ ticketObject.Name;
            fileRow = fileRow +','+ ticketObject.Quality_Assignee_Name__r.Name;
            fileRow = fileRow +','+ medicalAssigneeName;
            fileRow = fileRow +','+ ticketObject.RecordType.Name;
            fileRow = fileRow +','+ ticketObject.Search_Frequency__c;  
            fileRow = fileRow +','+ competedDate.formatGMT('MM/dd/yyyy hh:mm zz') ;
            fileRow = fileRow +','+ 'Failed'; 
            fileRow = fileRow +','+ 'Re-execution'; 
            fileRow = fileRow.replaceFirst(',','');
           
            userDataMap.put(ticketObject.Id,fileRow);  
             
        }
        
    }   
    // Finish Method
    global void finish(Database.BatchableContext BC) {
        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
    	// String for public group attachment.
    	//CHaRM-R5: Updated the "Status" Column to "Search Status" as per IPDR 191 By Dinesh Kumar
        String csvFileToPublic = 'Name (Ticket Review Number)'+','+'Quality Assignee Name'+','+'Medical Assignee Name'+','+'Record Type'+','+'Search Frequency'+','+'Time of Failure'+','+'Search Status'+','+'Action Required'+'\n';         
        for(Ticket_Review__c tickekReviewObject: [Select Id, Name, Quality_Assignee_Name__r.Email, medical_Assignee_Name__r.Email 
                                                  from Ticket_Review__c 
                                                  Where RecordTypeId =: AspenConstants.Recurrence_Search_RecordType_Id AND Id IN : ticketReviewIdSet]){ 
                                                      
                                                      
                                                      //Logic to CSV file for email attachment.
                                                      
                                                      Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
                                                      
                                                      String generatedCSVFile =  csvFileToPublic;
                                                      
                                                      generatedCSVFile = generatedCSVFile + userDataMap.get(tickekReviewObject.Id) + '\n';
                                                      csvFileToPublic = csvFileToPublic +  userDataMap.get(tickekReviewObject.Id) +'\n';
            Blob csvBlob = blob.valueOf(generatedCSVFile);
            String csvName = 'Ticket Review Failure Information.csv';
            csvAttachment.setFileName(csvName);
            csvAttachment.setBody(csvBlob);
                                                      
                                                      //set email and subject
                                                      List<String> toAddress = new List<String>();
                                                      toAddress.add(tickekReviewObject.Quality_Assignee_Name__r.Email);
                                                      if(tickekReviewObject.medical_Assignee_Name__r.Email != null){
                                                          toAddress.add(tickekReviewObject.medical_Assignee_Name__r.Email);
                                                      }                                       
                                                      
                                                      
                                                      //Email 
                                                      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                                      email.setToAddresses(toAddress);
                                                      email.setPlainTextBody('Hi,\n\n'+tickekReviewObject.Name+' Ticket Review Search is failed,Re-Execution Required');
                                                      email.setSubject('URGENT ACTION Required - Ticket Review Failure Information');
                                                      email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
                                                      if(toAddress.size() > 0)
                                                          emailMessageList.add(email);
                                                      
                                                  }
        
        //Logic for send email to public group
        if(emailMessageList.size() >  0){
            
     
            Set<Id> userIds = new Set<Id>();
            List<Group> groupList = new List<Group>();
            groupList = [SELECT Id, Name ,(select userOrGroupId from groupMembers) FROM Group Where Name= : System.label.Ticket_Review_Public_Group]; 
            
            //Fetch Group member through group name T&T Approver
            if(System.label.Ticket_Review_Public_Group != Null && groupList.size() > 0){
                
               
                
                for(GroupMember  groupMemberObj: groupList[0].groupMembers){
                    userIds.add(groupMemberObj.userOrGroupId);
                }
                
                //Fetch group members email id to sent email.
                List<String> groupMemberEmailList = new List<String>();
                for(User userObject : [SELECT Email FROM user WHERE id IN :userIds]) {
                    groupMemberEmailList.add(userObject.Email);
                }
                // CSV Attachment for Public group
                Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
                System.debug('CSV File'+ csvFileToPublic);
                Blob publicGroupCsvBlob = blob.valueOf(csvFileToPublic);
                String pulbicGroupCsvName = 'Ticket Review Failure Information.csv';
                csvAttachment.setFileName(pulbicGroupCsvName);
                csvAttachment.setBody(publicGroupCsvBlob);
                //Email 
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(groupMemberEmailList);
                email.setSubject('URGENT ACTION Required - Ticket Review Failure Information');
                email.setPlainTextBody('Ticket Search processes is failed, Re-Execution Required');
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
                if(groupMemberEmailList.size() > 0)
                    emailMessageList.add(email);
                
            }
            
            
            
            
        }
        
        Messaging.sendEmail(emailMessageList);
    }
    
}