public class NewUserCreationApex {
    
    
    public String domain = '@aspen.com.aspendeviq'; // Add with user Name , Pass Domain Name of Sandbox
    public String email ='Charm123.abbott@Abbott.com'; // Email That needs to Pass as Email of User
    public String firstName = 'add'; // First Name
    public String profileName = 'Aspen User';
    public String userNamePrefix = 'add_';
    
    //Need to pass Permission set names in List liks List<String> permissionSetName = new List<String>{'Bussiness_Admin'};
    public void UpsertUsers(List<String>permissinSet){
        
        // Map for Public Groups/Belong To Field 
        Map<string,List<string>> psWithPublicGroup = publicGroupMethod(permissinSet);
        Map<string,List<string>> psWithbelongTo = belongsToMethod(permissinSet);
        
        
        System.debug('Total Count of Belong as input -->'+psWithbelongTo.size());
        System.debug('Total Count of Public Group as input -->'+psWithPublicGroup.size());
        
        
        // Checking & creating new User based on available permission set.
        List<User> newUsers = new List<User>();
        
        
        for(String lastname : psWithPublicGroup.keySet()){
            system.debug('lastname -->'+lastname);
            for(Integer x=1;x<4;x++){ // Updated the loop for 4 User creation
                String username = lastname+x+domain; // User name Creation
                system.debug('username -->'+username);
                system.debug('Belongs To -->'+psWithbelongTo.get(lastName));
                system.debug('Public groups -->'+psWithPublicGroup.get(lastName));
                try{
                    if(  (psWithbelongTo.get(lastName) != null) ){ //If Permission set belongs to any Group
                        system.debug('Belongs To  -->'+psWithbelongTo.get(lastName));
                        newUsers.add(NewUser(firstName , lastname+x,email,userNamePrefix+username,psWithbelongTo.get(lastName) )); 
                    }else{//If Permission Set not Belong to any group
                        system.debug('Public Group is null -->');
                        newUsers.add(NewUserNoBelongTo(firstName , lastname+x,email,userNamePrefix+username)); 
                    }
                }catch(Exception e){
                    System.debug('Message -->'+e.getMessage());
                    system.debug('line number is -->'+e.getLineNumber());
                }
            }
        }
        //Upsert the user on the basis of User's External id
        Database.upsert(newUsers, User.External_ID__c);
        system.debug('User details -->'+newUsers);
        
        for(User u : newUsers){//Setting the passwords for user
            
            System.setPassword(u.Id, 'password@1235') ;
            System.debug('Password Reset Email sent to user --->');   
        }
        //Insert and Update Public Groups
        try{
            Map<String,List<User>> userNamewithUsers = userIdWithPermissionsetName(permissinSet);
            UpsertPublicGroup(psWithPublicGroup,userNamewithUsers);
        }catch(Exception e){
            System.debug('Message -->'+e.getMessage());
            system.Debug('line number is -->'+e.getLineNumber());
        }
        
        System.debug('**************** Successfully Added Public Groups, Permission Set to User ****************');
    }
    
    
    // Upsert Public Groups specific to Permission Sets	
    public  void UpsertPublicGroup(Map<string,List<string>> psWithPublicGroup ,Map<string,List<User>> userNamewithUsers ){
        system.debug('***** Inside UpsertPublicGroup Method *****');
        List<User> userList = new List<User>();
        //  List<User> userList = [SELECT Id, lastName ,username , External_ID__c FROM User WHERE lastName in :psWithPublicGroup.keySet()];
        system.debug('psWithPublicGroup.keySet()'+psWithPublicGroup.keySet());
        for(string str : psWithPublicGroup.keySet()){
            if(userNamewithUsers.containsKey(str)){
                userList.addAll(userNamewithUsers.get(str));
                system.debug('Inside loop userList'+userList);
            }
            
        }
        system.debug('total user found --->'+userList.size());
        system.debug('And Details are --->'+userList);  
        
        // To fetch All Public Group Id and Assiging Public Group to user
        Map<String ,Group> groupMap = new Map<String ,Group>();
        List<Group> allGroups = [SELECT Id, Name , developerName from Group];
        for( Group ag : allGroups){
            groupMap.put(ag.developerName,ag);
        }
        system.debug('Group Map -->'+groupMap);
        
        // Getting Group Id 
        List<Group> gttApproverlst = [SELECT Id, Name , developerName from Group where developerName = 'T_T_Approver' LIMIT 1];
        List<Group> gttReviewerlst = [SELECT Id, Name , developerName from Group where developerName = 'T_T_Reviewer' LIMIT 1];
        system.debug('approver -->'+gttApproverlst[0].Id+' --> reveiwer --->'+gttReviewerlst[0].Id);
        
        // To fetch All PermissionSet Id and Assiging Permission to user
        Map<String ,PermissionSet> permissionMap = new Map<String ,PermissionSet>();
        List<PermissionSet> allPermissionSet = [SELECT  Id, Name FROM PermissionSet];
        for( PermissionSet aps : allPermissionSet){
            permissionMap.put(aps.Name,aps);
        }
        system.debug('PermissionSet Map -->'+permissionMap);
        
        // Setting Default Permission Set to user
        
        List<PermissionSet> defaultPSId = [Select Id FROM PermissionSet WHERE Name = 'X123Compliance_Permission_Set_for_Platform_User' LIMIT 1];
        List<PermissionSet> PSCAId = [Select Id FROM PermissionSet WHERE Name = 'Complaint_Assessor' LIMIT 1];
        List<PermissionSet> PSCEIId = [Select Id FROM PermissionSet WHERE Name = 'Complaint_Evaluator_Investigator' LIMIT 1];
        List<PermissionSet> PSEITId = [Select Id FROM PermissionSet WHERE Name = 'Evaluation_Investigation_Task_Assignee' LIMIT 1];
        List<PermissionSet> PSVCIId = [Select Id FROM PermissionSet WHERE Name = 'Vigilance_Contact' LIMIT 1];
        List<PermissionSet> PSMETId = [Select Id FROM PermissionSet WHERE Name = 'Medical_Evaluator' LIMIT 1];	
        List<PermissionSet> PSTRMETId = [Select Id FROM PermissionSet WHERE Name = 'Ticket_Review_Medical_Assignee' LIMIT 1]; 
        List<PermissionSet> PSEVTAId = [Select Id FROM PermissionSet WHERE Name = 'Evaluation_Investigation_Task_Approver' LIMIT 1];	
        List<PermissionSet> PSQCAId = [Select Id FROM PermissionSet WHERE Name = 'Quality_Complaint_Approver' LIMIT 1]; 
        system.debug('userList.size()-->'+userList);
        for(User uid : userList){
            system.debug('psWithPublicGroup.containskey(uid.lastName)'+psWithPublicGroup.containskey(uid.lastName));
            if( psWithPublicGroup.containskey(uid.lastName) ){ 
                List<GroupMember> newGroupMembers = new List<GroupMember>();
                List<PermissionSetAssignment> newPermSetAssignments = new List<PermissionSetAssignment>();
                for(String ps : psWithPublicGroup.get(uid.lastName)){	 
                    system.debug('value of permission set -->'+ps);
                    
                    
                    if(ps == 'T_T_Task_Approver'){
                        GroupMember newGM = new GroupMember();
                        system.debug('Group T_T_Task_Approver -->'+gttApproverlst[0].Id);
                        newGM.UserOrGroupId=uid.Id;
                        newGM.GroupId = gttApproverlst[0].Id;
                        newGroupMembers.add(newGM);  
                    }else if(ps == 'T_T_Task_Reviewer'){
                        GroupMember newGM = new GroupMember();
                        system.debug('Group T_T_Task_Reviewer -->'+gttReviewerlst[0].Id);
                        newGM.UserOrGroupId=uid.Id;
                        newGM.GroupId = gttReviewerlst[0].Id;
                        newGroupMembers.add(newGM);  
                    }else{
                        //system.debug('Other Group name -->'+groupMap.get(ps).Id);
                        newGroupMembers.add(new GroupMember(UserOrGroupId = uid.Id,GroupId =  groupMap.get(ps).Id));
                    }
                }
                
                //insert  newGroupMembers;
                if(newGroupMembers.size() > 0){
                    Database.insert(newGroupMembers, false);
                }
                
                // Permission Set Assignment Start
                system.debug('Permission assignment Id -->'+permissionMap.get(uid.lastName).Id);
                system.debug('Permission assignment Name -->'+permissionMap.get(uid.lastName).Name);
                String psaName = permissionMap.get(uid.lastName).Name;
                system.debug('psaName-->'+psaName);
                Switch on psaName {
                    
                    when 'Business_Admin' {
                        newPermSetAssignments.add(new PermissionSetAssignment(AssigneeId=uid.Id,PermissionSetId = permissionMap.get(uid.lastName).Id));
                        newPermSetAssignments.add(new PermissionSetAssignment(PermissionSetId = defaultPSId[0].Id,AssigneeId=uid.Id));
                    }when 'IT_Admin_T_T' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'T_T_Task_Approver' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'T_T_Task_Reviewer' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Translation_Coordinator' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Evaluation_Investigation_Task_Assignee' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSCAId = new PermissionSetAssignment();
                        defaultPSCAId.AssigneeId=uid.Id;
                        defaultPSCAId.PermissionSetId = PSCAId[0].Id;
                        newPermSetAssignments.add(defaultPSCAId);
                        
                        PermissionSetAssignment defaultPSCEIId = new PermissionSetAssignment();
                        defaultPSCEIId.AssigneeId=uid.Id;
                        defaultPSCEIId.PermissionSetId = PSCEIId[0].Id;
                        newPermSetAssignments.add(defaultPSCEIId);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Medical_Opinion_Assignee' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Vigilance_Contact' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment mepsa = new PermissionSetAssignment();
                        mepsa.AssigneeId=uid.Id;
                        mepsa.PermissionSetId = PSMETId[0].Id;
                        newPermSetAssignments.add(mepsa); 
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Medical_Evaluator' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment vcpsa = new PermissionSetAssignment();
                        vcpsa.AssigneeId=uid.Id;
                        vcpsa.PermissionSetId = PSVCIId[0].Id;
                        newPermSetAssignments.add(vcpsa);
                        
                        PermissionSetAssignment trmepsa = new PermissionSetAssignment();
                        trmepsa.AssigneeId=uid.Id;
                        trmepsa.PermissionSetId = PSTRMETId[0].Id;
                        newPermSetAssignments.add(trmepsa);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Ticket_Review_Medical_Assignee' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment mepsa = new PermissionSetAssignment();
                        mepsa.AssigneeId=uid.Id;
                        mepsa.PermissionSetId = PSMETId[0].Id;
                        newPermSetAssignments.add(mepsa); 
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Ticket_Review_Quality_Assignee' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Evaluation_Investigation_Task_Approver' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment qcapsa = new PermissionSetAssignment();
                        qcapsa.AssigneeId=uid.Id;
                        qcapsa.PermissionSetId = PSQCAId[0].Id;
                        newPermSetAssignments.add(qcapsa); 
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Quality_Complaint_Approver' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment eitapsa = new PermissionSetAssignment();
                        eitapsa.AssigneeId=uid.Id;
                        eitapsa.PermissionSetId = PSEVTAId[0].Id;
                        newPermSetAssignments.add(eitapsa);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Return_Coordinator' {
                        
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                        
                    }when 'Complaint_Evaluator_Investigator' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSCAId = new PermissionSetAssignment();
                        defaultPSCAId.AssigneeId=uid.Id;
                        defaultPSCAId.PermissionSetId = PSCAId[0].Id;
                        newPermSetAssignments.add(defaultPSCAId);
                        
                        PermissionSetAssignment defaultPSEITId = new PermissionSetAssignment();
                        defaultPSEITId.AssigneeId=uid.Id;
                        defaultPSEITId.PermissionSetId =PSEITId[0].Id;
                        newPermSetAssignments.add(defaultPSEITId);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Complaint_Assessor' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSEITId = new PermissionSetAssignment();
                        defaultPSEITId.AssigneeId=uid.Id;
                        defaultPSEITId.PermissionSetId =PSEITId[0].Id;
                        newPermSetAssignments.add(defaultPSEITId);
                        
                        PermissionSetAssignment defaultPSCEIId = new PermissionSetAssignment();
                        defaultPSCEIId.AssigneeId=uid.Id;
                        defaultPSCEIId.PermissionSetId = PSCEIId[0].Id;
                        newPermSetAssignments.add(defaultPSCEIId);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Technical_Customer_Letter_Approver' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Regulatory_Customer_Letter_Approver' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Quality_Customer_Letter_Approver'{
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when 'Quality_non_Complaint' {
                        PermissionSetAssignment newPSA = new PermissionSetAssignment();
                        newPSA.AssigneeId=uid.Id;
                        newPSA.PermissionSetId = permissionMap.get(uid.lastName).Id;
                        newPermSetAssignments.add(newPSA);
                        
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId=uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }when else {
                        PermissionSetAssignment defaultPSA = new PermissionSetAssignment();
                        defaultPSA.AssigneeId = uid.Id;
                        defaultPSA.PermissionSetId = defaultPSId[0].Id;
                        newPermSetAssignments.add(defaultPSA);
                    }
                }
                
                if(newGroupMembers.size() > 0){
                    Database.insert(newPermSetAssignments, false);
                    
                }
                // Permission Set Assigment End
            }
        }
        system.debug('***** Exiting UpsertPublicGroup Method *****');
    }
    
    
    
    // Creating new user account
    public User NewUserNoBelongTo( String firstName,  String lastName ,String email, string userName){
        
        List<Profile> profilelst = [SELECT Id, Name FROM Profile WHERE Name =:profileName LIMIT 1];       
        return new User(
            firstName = firstName,
            lastName = lastName,
            email = email,
            isActive = true,
            profileId = profilelst[0].Id,
            alias = lastName.substring(1,5),
            username = userName,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            External_ID__c = userName
        );
    }
    
    
    public User NewUser( String firstName,  String lastName ,String email, string userName ,List<String> belongsTo){
        system.debug('while creating user with belong to -->'+belongsTo[0]);
        List<Profile> profilelst = [SELECT Id, Name FROM Profile WHERE Name =:profileName LIMIT 1];       
        
        return new User(
            firstName = firstName,
            lastName = lastName,
            email = email,
            isActive = true,
            profileId = profilelst[0].Id,
            alias = lastName.substring(1,5),
            username = userName,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Belongs_To__c = belongsTo[0],
            Belongs_to_Text__c = belongsTo[0],
            External_ID__c = userName
        );
    }
    //This method is used to set Belongs to according to the Permission set
    public Map<string,List<string>> belongsToMethod(List<String>permSetNames){
        Map<string,List<string>> psWithbelongTo = new Map<string,List<string>> ();
        for(String psName : permSetNames){
            Switch on psName {
                
                when 'Business_Admin' {
                    List<string> belongTo_BA = new List<string>();
                    belongTo_BA.add('');
                    psWithbelongTo.put(psName,belongTo_BA);
                }when 'IT_Admin_T_T' {
                    List<string> belongTo_ITAdmin= new List<string>();
                    belongTo_ITAdmin.add('TIMRA9');
                    psWithbelongTo.put('IT_Admin_T_T',belongTo_ITAdmin);
                }when 'T_T_Task_Approver' {
                    List<string> belongTo_TT = new List<string>();
                    belongTo_TT.add('TRE9');
                    psWithbelongTo.put('T_T_Task_Approver',belongTo_TT);
                }when 'T_T_Task_Reviewer' {
                    List<string> belongTo_TTT = new List<string>();
                    belongTo_TTT.add('TT17');
                    psWithbelongTo.put('T_T_Task_Reviewer',belongTo_TTT); 
                }when 'Translation_Coordinator' {
                    List<string> belongTo_TC = new List<string>();
                    belongTo_TC.add('Tran10');
                    psWithbelongTo.put('Translation_Coordinator',belongTo_TC);
                }when 'Evaluation_Investigation_Task_Assignee' {
                    List<string> belongTo_EI = new List<string>();
                    belongTo_EI.add('PEA2;PEI3;TA5;CRA7');
                    psWithbelongTo.put('Evaluation_Investigation_Task_Assignee',belongTo_EI); 
                }when 'Medical_Opinion_Assignee' {
                    List<string> belongTo_MOA = new List<string>();
                    belongTo_MOA.add('META1;META18');
                    psWithbelongTo.put('Medical_Opinion_Assignee',belongTo_MOA);
                }when 'Vigilance_Contact' {
                    List<string> belongTo_VC = new List<string>();
                    belongTo_VC.add('RTC12;META1;ME11;');
                    psWithbelongTo.put('Vigilance_Contact',belongTo_VC);
                }when 'Medical_Evaluator' {
                    List<string> belongTo_ME = new List<string>();
                    belongTo_ME.add('META1;ME11');
                    psWithbelongTo.put('Medical_Evaluator' ,belongTo_ME);
                }when 'Ticket_Review_Medical_Assignee' {
                    List<string> belongTo_TRMA = new List<string>();
                    belongTo_TRMA.add('');
                    psWithbelongTo.put(psName,belongTo_TRMA); 
                }when 'Ticket_Review_Quality_Assignee' {
                    List<string> belongTo_TRQE = new List<string>();
                    belongTo_TRQE.add('');
                    psWithbelongTo.put(psName,belongTo_TRQE); 
                }when 'Evaluation_Investigation_Task_Approver' {
                    List<string> belongTo_EIT = new List<string>();
                    belongTo_EIT.add('PEA4;TA6');
                    psWithbelongTo.put('Evaluation_Investigation_Task_Approver',belongTo_EIT);
                }when 'Quality_Complaint_Approver' {
                    List<string> belongTo_QCA = new List<string>();
                    belongTo_QCA.add('PEA4;TA6');
                    psWithbelongTo.put('Quality_Complaint_Approver' ,belongTo_QCA);
                }when 'Return_Coordinator' {
                    List<string> belongTo_RC = new List<string>();
                    belongTo_RC.add('RA16');
                    psWithbelongTo.put('Return_Coordinator',belongTo_RC); 
                }when 'Complaint_Evaluator_Investigator' {
                    List<string> belongTo_CEI = new List<string>();
                    belongTo_CEI.add('PEA2;PEI3;TA5;CRA7');
                    psWithbelongTo.put('Complaint_Assessor',belongTo_CEI);
                }when 'Complaint_Assessor' {
                    List<string> belongTo_CA = new List<string>();
                    belongTo_CA.add('PEA2;PEI3;TA5;CRA7');
                    psWithbelongTo.put('Complaint_Assessor',belongTo_CA);
                }when 'Technical_Customer_Letter_Approver' {
                    List<string> belongTo_TCLA= new List<string>();
                    belongTo_TCLA.add('IN-TA1');
                    psWithbelongTo.put('Technical_Customer_Letter_Approver',belongTo_TCLA); 
                }when 'Regulatory_Customer_Letter_Approver' {
                    List<string> belongTo_RCLA= new List<string>();
                    belongTo_RCLA.add('IN-RA1');
                    psWithbelongTo.put('Regulatory_Customer_Letter_Approver',belongTo_RCLA); 
                }when 'Quality_Customer_Letter_Approver'{
                    List<string> belongTo_QCLA= new List<string>();
                    belongTo_QCLA.add('CRQA');
                    psWithbelongTo.put('Quality_Customer_Letter_Approver',belongTo_QCLA);  
                }
                when 'Quality_non_Complaint' {
                    List<string> belongTo_QNC= new List<string>();
                    belongTo_QNC.add('CRA8');
                    psWithbelongTo.put('Quality_non_Complaint',belongTo_QNC);
                }
                when else {
                    List<string> belongTo_Default= new List<string>();
                    belongTo_Default.add('CRA8;CRQA;IN-RA1;IN-TA1;PEA2;PEI3;TA5;CRA7;RA16;TA6;PEA4;META1;ME11;RTC12;META18;Tran10;TT17;TRE9;TIMRA9;'); 
                    psWithbelongTo.put('X123Compliance_Permission_Set_for_Platform_User',belongTo_Default);
                }
            }
        }
        
        System.debug('Belong to -->'+psWithbelongTo);
        return psWithbelongTo;
    }
    
    //This method is used to create public group according to the Permission Sets
    public Map<string,List<string>> publicGroupMethod(List<String>permSetNames){
        Map<string,List<string>> psWithPublicGroup = new Map<string,List<string>> ();
        
        for(String psName : permSetNames){
            Switch on psName {
                
                when 'Business_Admin' {
                    List<string> groupNames_BA = new List<string>();
                    groupNames_BA.add('ADD_Users');
                    groupNames_BA.add('Business_Admin');
                    groupNames_BA.add('Adhoc_Observation_Assignee');
                    groupNames_BA.add('Adhoc_Quality_Non_Complaint_Observation');
                    psWithPublicGroup.put('Business_Admin',groupNames_BA);
                }when 'IT_Admin_T_T' {
                    List<string> groupNames_IT = new List<string>();	
                    groupNames_IT.add('ADD_Users');
                    groupNames_IT.add('IT_Admin_T_T');
                    psWithPublicGroup.put('IT_Admin_T_T',groupNames_IT);
                }when 'T_T_Task_Approver' {
                    List<string> groupNames_TT = new List<string>();
                    groupNames_TT.add('ADD_Users');
                    groupNames_TT.add('T_T_Task_Approver');
                    psWithPublicGroup.put('T_T_Task_Approver',groupNames_TT); 
                }when 'T_T_Task_Reviewer' {
                    List<string> groupNames_TTT = new List<string>();
                    groupNames_TTT.add('ADD_Users');
                    groupNames_TTT.add('T_T_Task_Reviewer');
                    psWithPublicGroup.put('T_T_Task_Reviewer',groupNames_TTT);  
                }when 'Translation_Coordinator' {
                    List<string> groupNames_TC = new List<string>();
                    groupNames_TC.add('ADD_Users');
                    psWithPublicGroup.put('Translation_Coordinator',groupNames_TC);   
                }when 'Evaluation_Investigation_Task_Assignee' {
                    List<string> groupNames_EI = new List<string>();
                    groupNames_EI.add('ADD_Users');
                    groupNames_EI.add('Evaluator_Investigator');
                    groupNames_EI.add('Quality_Complaint');
                    groupNames_EI.add('Prod_eval_Assessor');
                    psWithPublicGroup.put('Evaluation_Investigation_Task_Assignee',groupNames_EI);
                }when 'Medical_Opinion_Assignee' {
                    List<string> groupNames_MOA = new List<string>();
                    groupNames_MOA.add('ADD_Users');
                    psWithPublicGroup.put('Medical_Opinion_Assignee',groupNames_MOA);
                }when 'Vigilance_Contact' {
                    List<string> groupNames_VC = new List<string>();
                    groupNames_VC.add('ADD_Users');
                    groupNames_VC.add('Vigilance_Contact');
                    groupNames_VC.add('Medical_Evaluator');
                    psWithPublicGroup.put('Vigilance_Contact',groupNames_VC); 
                }when 'Medical_Evaluator' {
                    List<string> groupNames_ME = new List<string>();
                    groupNames_ME.add('ADD_Users');
                    groupNames_ME.add('Medical_Evaluator');
                    groupNames_ME.add('Vigilance_Contact');
                    psWithPublicGroup.put('Medical_Evaluator',groupNames_ME);
                }when 'Ticket_Review_Medical_Assignee' {
                    List<string> groupNames_TRM = new List<string>();
                    groupNames_TRM.add('ADD_Users');
                    groupNames_TRM.add('Medical_Evaluator');
                    psWithPublicGroup.put('Ticket_Review_Medical_Assignee',groupNames_TRM); 
                }when 'Ticket_Review_Quality_Assignee' {
                    List<string> groupNames_TRQ = new List<string>();
                    groupNames_TRQ.add('ADD_Users');
                    groupNames_TRQ.add('FA_Quality_Assignee');
                    psWithPublicGroup.put('Ticket_Review_Quality_Assignee',groupNames_TRQ);
                }when 'Evaluation_Investigation_Task_Approver' {
                    List<string> groupNames_EIT = new List<string>();
                    groupNames_EIT.add('ADD_Users');
                    psWithPublicGroup.put('Evaluation_Investigation_Task_Approver',groupNames_EIT); 
                }when 'Quality_Complaint_Approver' {
                    List<string> groupNames_QCA = new List<string>();
                    groupNames_QCA.add('ADD_Users');
                    psWithPublicGroup.put('Quality_Complaint_Approver' ,groupNames_QCA);
                }when 'Return_Coordinator' {
                    List<string> groupNames_RC = new List<string>();
                    groupNames_RC.add('ADD_Users');
                    psWithPublicGroup.put('Return_Coordinator',groupNames_RC); 
                }when 'Complaint_Evaluator_Investigator' {
                    List<string> groupNames_EITA = new List<string>();
                    groupNames_EITA.add('ADD_Users');
                    groupNames_EITA.add('Evaluator_Investigator');
                    groupNames_EITA.add('Quality_Complaint');
                    groupNames_EITA.add('Prod_eval_Assessor');
                    psWithPublicGroup.put('Complaint_Evaluator_Investigator',groupNames_EITA);
                }when 'Complaint_Assessor' {
                    List<string> groupNames_CA = new List<string>();
                    groupNames_CA.add('ADD_Users');
                    groupNames_CA.add('Evaluator_Investigator');
                    groupNames_CA.add('Quality_Complaint');
                    groupNames_CA.add('Prod_eval_Assessor');
                    psWithPublicGroup.put('Complaint_Assessor',groupNames_CA);
                }when 'Technical_Customer_Letter_Approver' {
                    List<string> groupNames_TCLA = new List<string>();
                    groupNames_TCLA.add('ADD_Users');
                    groupNames_TCLA.add('Quality_non_Complaint');
                    groupNames_TCLA.add('Technical_Customer_Letter_Approver');
                    psWithPublicGroup.put('Technical_Customer_Letter_Approver',groupNames_TCLA);
                }when 'Regulatory_Customer_Letter_Approver' {
                    List<string> groupNames_RCLA = new List<string>();
                    groupNames_RCLA.add('ADD_Users');
                    groupNames_RCLA.add('Quality_non_Complaint');
                    groupNames_RCLA.add('Regulatory_Customer_Letter_Approver');
                    psWithPublicGroup.put('Regulatory_Customer_Letter_Approver',groupNames_RCLA);
                }when 'Quality_Customer_Letter_Approver'{
                    List<string> groupNames_QCLA = new List<string>();
                    groupNames_QCLA.add('ADD_Users');
                    groupNames_QCLA.add('Quality_Customer_Letter_Approver');
                    groupNames_QCLA.add('Quality_non_Complaint');
                    psWithPublicGroup.put('Quality_Customer_Letter_Approver',groupNames_QCLA);   
                }
                when 'Quality_non_Complaint' {
                    List<string> groupNames_QNC = new List<string>();
                    groupNames_QNC.add('ADD_Users');
                    groupNames_QNC.add('Quality_non_Complaint');
                    psWithPublicGroup.put('Quality_non_Complaint',groupNames_QNC);	
                }
                when else {
                    List<string> groupNames_Default = new List<string>();
                    groupNames_Default.add('ADD_Users');
                    groupNames_Default.add('Quality_non_Complaint');
                    groupNames_Default.add('Quality_Customer_Letter_Approver');
                    groupNames_Default.add('Regulatory_Customer_Letter_Approve');
                    groupNames_Default.add('Technical_Customer_Letter_Approver');
                    groupNames_Default.add('Evaluator_Investigator');
                    groupNames_Default.add('Quality_Complaint');
                    groupNames_Default.add('Prod_eval_Assessor');
                    groupNames_Default.add('FA_Quality_Assignee');
                    groupNames_Default.add('Medical_Evaluator');
                    groupNames_Default.add('Vigilance_Contact');
                    groupNames_Default.add('T_T_Reviewer');
                    groupNames_Default.add('T_T_Approver');
                    groupNames_Default.add('IT_Admin_T_T');
                    groupNames_Default.add('Business_Admin');
                    groupNames_Default.add('Adhoc_Observation_Assignee');
                    groupNames_Default.add('Adhoc_Quality_Non_Complaint_Observation');
                    
                    psWithPublicGroup.put('X123Compliance_Permission_Set_for_Platform_User',groupNames_Default);
                }
            }
        }
        System.debug('Group map to -->'+psWithPublicGroup);
        return psWithPublicGroup;
    }
    
    //This method is used to maintain the Uniquenes between Permission set name with Last Name
    public  Map<String,List<User>>  userIdWithPermissionsetName(List<String> lstpermissionsetName){
        
        Map<String,List<User>> userWithUserNames = new Map<String,List<User>>();
        for(user userObj :[SELECT Id, lastName,username,External_ID__c FROM User]){
            String lastname ='';
            if(userObj.lastName.contains('1') || userObj.lastName.contains('2') || userObj.lastName.contains('3')){
                lastname = userObj.lastName.substring(0,userObj.lastname.length()-1);
                if(!lstpermissionsetName.contains(lastname))
                    continue;
                List<user> userInfo = new List<User>();
                userObj.LastName = lastname;
                userInfo.add(userObj);
                if(userWithUserNames.containsKey(lastname))
                    userWithUserNames.get(lastname).add(userObj);
                else
                    userWithUserNames.put(lastname,userInfo);
            }
        }
        System.debug('@@@userWithUserNames'+userWithUserNames);
        System.debug('@@@userWithUserNames'+userWithUserNames.size());
        return userWithUserNames;
    }
}