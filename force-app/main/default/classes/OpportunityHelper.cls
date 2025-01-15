public with sharing class OpportunityHelper {
        
    public static void setType(List<Opportunity> newOpps) {
        System.debug('Input Opportunities: ' + newOpps); // Log the input list

            if (newOpps == null || newOpps.isEmpty()) {
                return; // Exit if the list is null or empty
            }
            else if (newOpps !=null){
                List<Opportunity> oppTypeUpdates = new List<Opportunity>();
                    for(Opportunity opp : newOpps){
                        System.debug('Any Data in Opp: ' +opp);
                        opp.Type = 'New Customer';
                        oppTypeUpdates.add(opp);
                    } 
                }
            }
    public static void validateCloseOpportunity(List<Opportunity> deletedOpps){
            if(!deletedOpps.isEmpty()){
                for(Opportunity oldOpp : deletedOpps){
                    System.debug('Old Opp exists ' +oldOpp);
                    oldOpp.addError('Cannot delete closed opportunity');
                    }
                }
            }
    public static void insertTask(List<Opportunity> insertedOpps) {
        List<Task> oppTasks = new List<Task>();
            for(Opportunity opp : insertedOpps){  
                    Task tsk = new Task();
                    tsk.Subject = 'Call Primary Contact';
                    tsk.WhatId = opp.Id;
                    tsk.OwnerId = opp.OwnerId;
                    tsk.ActivityDate = Date.today().addDays(3);
                    oppTasks.add(tsk);
                        }
            if(!oppTasks.isEmpty()){
                        insert oppTasks;
                }                                
            } 
    public static void updateDescriptionFromStage(List<Opportunity> updatedStageOpps){
            for(Opportunity opp : updatedStageOpps){
                opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }
        }
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> deletedOpps) {
            // Step 1: Group Opportunities by OwnerId
            Map<Id, List<Opportunity>> ownerOppsMap = new Map<Id, List<Opportunity>>();
            for (Opportunity opp : deletedOpps) {
                if (!ownerOppsMap.containsKey(opp.OwnerId)) {
                    ownerOppsMap.put(opp.OwnerId, new List<Opportunity>());
                }
                ownerOppsMap.get(opp.OwnerId).add(opp);
            }
            Map<Id, String> ownerEmailMap = new Map<Id, String>();    // Step 2: Query email addresses for the Owners
            for (User user : [SELECT Id, Email FROM User WHERE Id IN :ownerOppsMap.keySet()]) {
                ownerEmailMap.put(user.Id, user.Email);
            }

            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>(); // Step 3: Create one email per user
            for (Id ownerId : ownerOppsMap.keySet()) {
                if (ownerEmailMap.containsKey(ownerId)) {
                    List<Opportunity> userOpps = ownerOppsMap.get(ownerId);
        
                    String emailBody = 'The following Opportunities have been deleted:\n\n';
                    for (Opportunity opp : userOpps) {
                        emailBody += '- ' + opp.Name + '\n';
                    }
        
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { ownerEmailMap.get(ownerId) });
                    mail.setSubject('Opportunities Deleted Notification');
                    mail.setPlainTextBody(emailBody);
                    mails.add(mail);
                }
            }
            if (!mails.isEmpty()) {
                try {
                Messaging.sendEmail(mails);
            } catch (Exception e){
                System.debug('Exception: ' + e.getMessage());
            }
        }
    }
/* assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact. */ 

    public static void assignPrimaryContact(Map<Id,Opportunity> undeletedOppsMap) {        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : undeletedOppsMap.values()) {
            if (opp.accountId != null) {
                accountIds.add(opp.AccountId);   System.debug('which acct ids? ' +accountIds );
            }
        }
    List<Contact> contactList = [SELECT Id, Title, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'VP Sales' WITH USER_MODE];
        System.debug('which contacts in list? ' +contactList);

        Map<Id, Contact> contactMap = new Map<Id, Contact>();
            for (Contact con : contactList) {
                contactMap.put(con.AccountId, con);
                System.debug('contacts in map? ' +contactMap);
            }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();    
            for (Opportunity oppForPrime : undeletedOppsMap.values()) {
                Contact primaryContact = contactMap.get(oppForPrime.AccountId);
                    if (oppForPrime.Primary_Contact__c == null) {
                        Opportunity oppToUpdate = new Opportunity(Id = oppForPrime.Id, Primary_Contact__c = primaryContact.Id);
                        oppsToUpdate.add(oppToUpdate);
                        System.debug('do I get updated Opps ' +oppsToUpdate);              
                }
            } 
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
// assignPrimaryContact in before Update for CEO:
public static void assignPrimaryContactCEO(Map<Id,Opportunity> oppPrimContactMap) { 
    Set<Id> accountIds = new Set<Id>();
    for(Opportunity opp : oppPrimContactMap.values()){
        if (opp.accountId != null){
            accountIds.add(opp.AccountId);
            }
    }    
    Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
    Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : oppPrimContactMap.values()){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }
}    
        
    








