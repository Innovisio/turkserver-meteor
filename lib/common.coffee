# Create a global object for storing things
# This is exported so it doesn't need @
TurkServer = TurkServer || {}

TestUtils = TestUtils || {}

# Backwards compat, and for cohesion while programming
TurkServer.group = Partitioner.group
TurkServer.partitionCollection = Partitioner.partitionCollection

@Batches = new Mongo.Collection("ts.batches")
@Treatments = new Mongo.Collection("ts.treatments")
# TODO rename these instances
@Experiments = new Mongo.Collection("ts.experiments")

@LobbyStatus = new Mongo.Collection("ts.lobby")
@Logs = new Mongo.Collection("ts.logs")

@RoundTimers = new Mongo.Collection("ts.rounds")
TurkServer.partitionCollection RoundTimers, {index: {index: 1}}

@Workers = new Mongo.Collection("ts.workers")
@Assignments = new Mongo.Collection("ts.assignments")

@WorkerEmails = new Mongo.Collection("ts.workeremails")
@Qualifications = new Mongo.Collection("ts.qualifications")
@HITTypes = new Mongo.Collection("ts.hittypes")
@HITs = new Mongo.Collection("ts.hits")

@ErrMsg =
  # authentication
  unexpectedBatch: "This HIT is not recognized."
  batchInactive: "This task is currently not accepting new assignments."
  batchLimit: "You've attempted or completed the maximum number of HITs allowed in this group. Please return this assignment."
  simultaneousLimit: "You are already connected through another HIT, or you previously returned a HIT from this group. If you still have the HIT open, please complete that one first."
  alreadyCompleted: "You have already completed this HIT."
  # operations
  authErr: "You are not logged in"
  stateErr: "You can't perform that operation right now"
  notAdminErr: "Not logged in as admin"
  adminErr: "Operation not permitted by admin"
  # Stuff
  usernameTaken: "Sorry, that username is taken."
  userNotInLobbyErr: "User is not in lobby"

# TODO move this to a more appropriate location
Meteor.methods
  "ts-delete-treatment": (id) ->
    TurkServer.checkAdmin()
    if Batches.findOne({ treatmentIds: { $in: [id] } })
      throw new Meteor.Error(403, "can't delete treatments that are used by existing batches")

    Treatments.remove(id)

# Helpful functions
TurkServer.isAdmin = ->
  userId = Meteor.userId()
  return false unless userId
  return Meteor.users.findOne(
    _id: userId
    "admin": { $exists: true }
  , fields:
    "admin" : 1
  )?.admin || false

TurkServer.checkNotAdmin = ->
  if Meteor.isClient
    # Don't register reactive dependencies on userId for a client check
    throw new Meteor.Error(403, ErrMsg.adminErr) if Deps.nonreactive(-> TurkServer.isAdmin())
  else
    throw new Meteor.Error(403, ErrMsg.adminErr) if TurkServer.isAdmin()

TurkServer.checkAdmin = ->
  if Meteor.isClient
    throw new Meteor.Error(403, ErrMsg.notAdminErr) unless Deps.nonreactive(-> TurkServer.isAdmin())
  else
    throw new Meteor.Error(403, ErrMsg.notAdminErr) unless TurkServer.isAdmin()
