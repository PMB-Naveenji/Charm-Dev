/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) Capgemini.
* @What  : ScheduleBatchJobController.
* @Why   : This  class is used to Schdule the Batch Class.
* @When  : 20- July -2021.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                      Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid  				   20 July-2021				Work ID / Case ID       Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid  				   20 July-2021			    Ticket Review Devlopment          Added logic for MIR Batch scheduler 
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ScheduleBatchJobController {
    
    public Integer hours {get;set;}
    public Integer minutes {get;set;}
  
   
    
    public List<SelectOption> getperiodHours()
    {
        List<SelectOption> options = new List<SelectOption>();
  
        options.add(new SelectOption('--None--','--None--'));
        for(Integer index = 0;index<24;index++){
             options.add(new SelectOption(String.valueOf(index),String.valueOf(index)));
        }        
        return options;
    }

    
 
    public List<SelectOption> getPeriodMinutes()
    {
        List<SelectOption> options = new List<SelectOption>();
  
        options.add(new SelectOption('--None--','--None--'));
        for(Integer index=0;index<60;index++){
			 options.add(new SelectOption(String.valueOf(index),String.valueOf(index)));            
       }
        
        return options;
    }
    
    
    public void scheduleBatchJob(){
        String message = 'Success' ;
        List<CronTrigger> cronList = new List<Crontrigger>();
        List<CronJobDetail> cronJobList = new List<CronJobDetail>();
        cronJobList = [Select Id,Name From CronJobDetail Where Name = 'Ticket Batch Job'];
        
        if(cronJobList.size() > 0){
            cronList = [select Id from CronTrigger where CronJobDetailId = : cronJobList[0].Id];   
        }
        
        if(cronJobList.size() == 0 ){
            TicketReviewRecodErrorBatchSchedular tickedRecordSchedulerobj = new TicketReviewRecodErrorBatchSchedular();
            String cronExpression = '0 '+minutes+' */'+hours+' ? * *';
            try{
              System.schedule('Ticket Batch Job',cronExpression,tickedRecordSchedulerobj);  
            }catch(Exception e){
                message = 'Error';
			} 
        }else{
            System.abortJob(cronList[0].Id);
            TicketReviewRecodErrorBatchSchedular tickedRecordSchedulerobj = new TicketReviewRecodErrorBatchSchedular();
            String cronExpression = '0 '+minutes+' */'+hours+' ? * *';
            try{
              System.schedule('Ticket Batch Job',cronExpression,tickedRecordSchedulerobj);  
            }catch(Exception e){
                message = 'Error';
			} 
            
        }
        if(message == 'Success'){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Batch Scheduled Successfully For Every '+hours+' Hours and '+minutes+' Minutes'));  
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Batch Not Scheduled'));
        }
    }
    
}