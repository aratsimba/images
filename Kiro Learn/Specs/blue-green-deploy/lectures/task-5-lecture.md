# 📚 Task 5: Application Revision with AppSpec File — Lecture

---

## Task 5 (Parent) — Application Revision with AppSpec File

### 🎯 What Are We Building?

In this task, we're creating the "delivery package" that CodeDeploy will install on our servers. Think of it like packing a moving box — you need the stuff you're moving (your application files), a packing list that says where everything goes (the AppSpec file), and special instructions for the movers (lifecycle hook scripts). Once it's all packed up, we'll ship the box to a storage locker (Amazon S3) so CodeDeploy can grab it when it's time to deploy.

### 💡 Key Concept: The AppSpec File

Imagine you're hiring a moving company. You wouldn't just hand them a pile of boxes and say "figure it out." You'd give them a checklist:

- "Put the kitchen boxes in the kitchen" → That's the **files section** (tells CodeDeploy which files go where on the server)
- "Before you bring stuff in, clear out the old furniture" → That's the **BeforeInstall hook** (a script that runs before the new app is placed)
- "After you set things down, make sure the doors lock" → That's the **AfterInstall hook** (a script that sets permissions)
- "Walk through and make sure everything works" → That's the **ValidateService hook** (a script that checks the app is actually running)

The AppSpec file (short for "Application Specification") is that checklist — it's a YAML file (a human-readable format for structured data) that tells CodeDeploy exactly what to do at each step of the deployment.

### 🔍 How Does It Work?

1. **Write the AppSpec file** — Define which files to copy and where, plus which scripts to run at each lifecycle stage
2. **Create the hook scripts** — Small shell scripts (text files with commands) that handle tasks like stopping the old server, setting file permissions, and verifying the new app is healthy
3. **Bundle everything into a zip** — Pack the AppSpec file, your app files, and the scripts into a single archive (like a .zip file you'd email someone)
4. **Upload to S3** — Store the zip in an S3 bucket (Amazon's cloud storage) so CodeDeploy can fetch it during deployment

### 🔧 Our Game Plan

```
App files + AppSpec + Scripts
        ↓
   [ Zip Bundle ]
        ↓
   [ Upload to S3 ]
        ↓
   CodeDeploy fetches it during deployment
```

We'll build two things:
- A **RevisionManager** that generates the AppSpec, bundles everything, and handles S3 uploads
- **Hook scripts** (before_install, after_install, validate_service) that run at key moments during deployment

### 💬 Quick Check

If the ValidateService hook script fails (returns an error), what do you think happens to the deployment?

**Answer:** The deployment stops and is marked as failed! Just like in the moving company analogy — if the walk-through reveals a broken pipe, you wouldn't sign off on the move. CodeDeploy treats a non-zero exit code from any lifecycle hook as a failure, which halts the deployment and keeps traffic on the original (blue) environment. This is a safety net that prevents broken code from reaching your users.

---

## Task 5.1 — Implement AppSpec Generation and Bundling

### 🎯 What Are We Building?

We're building the "recipe card" and "ingredient kit" for our deployment. Specifically, we'll create:
- A Python function that writes the AppSpec file (the recipe card that tells CodeDeploy what to do)
- Three shell scripts (small text files with commands) that act as the "steps" in the recipe
- A Python function that zips everything together into a neat package

### 💡 Key Concept: YAML and Lifecycle Hooks

Think of YAML (a text format for structured data) like a restaurant order ticket. It's easy for both humans and computers to read:

```
Order:
  Table: 5
  Items:
    - Burger
    - Fries
  Special Instructions:
    - No onions
```

Our AppSpec file works the same way — it lists files to copy and scripts to run. The "lifecycle hooks" are like the stages of preparing a meal:

- **BeforeInstall** = "Clear the table" → Stop the old server, clean up old files
- **AfterInstall** = "Set the table" → Set the right permissions on the new files
- **ValidateService** = "Taste test" → Check that the app is actually serving pages

### 🔍 How Does It Work?

1. **generate_appspec()** takes a list of file mappings (what goes where) and hooks (which scripts run when), and produces a YAML string — the AppSpec content
2. **Shell scripts** are simple bash files. For example, the validate script just curls localhost (sends a web request to itself) to confirm the app responds
3. **create_revision_bundle()** takes the AppSpec content, the app source directory, and an output path, then creates a zip file containing everything CodeDeploy needs
4. The zip structure must have the `appspec.yml` at the root — CodeDeploy looks for it there specifically

### 🔧 Our Game Plan

```
generate_appspec(mappings, hooks)
        ↓
   appspec.yml content (YAML string)
        ↓
create_revision_bundle(appspec, source_dir, output.zip)
        ↓
   [ revision.zip ]
   ├── appspec.yml
   ├── src/index.html
   └── scripts/
       ├── before_install.sh
       ├── after_install.sh
       └── validate_service.sh
```

### 💬 Quick Check

Why do you think the AppSpec file needs to be at the very root of the zip archive, rather than inside a subfolder?

**Answer:** CodeDeploy is like a delivery driver who always checks the front door first — it looks in one specific, predictable place. When CodeDeploy extracts the zip, it immediately looks for `appspec.yml` at the top level. If it's buried in a subfolder, CodeDeploy won't find it and the deployment will fail with an "invalid revision" error. It's a convention that keeps things simple and consistent.

---

## Task 5.2 — Implement S3 Upload and Revision Location

### 🎯 What Are We Building?

In the last task we packed our deployment into a zip file. Now we need somewhere to store it so CodeDeploy can grab it. We're building the "storage locker" side of things — creating an S3 bucket (Amazon's cloud storage service, like a folder in the cloud), uploading our zip there, and creating a "shipping label" (the RevisionLocation dictionary) that tells CodeDeploy exactly where to find the package.

### 💡 Key Concept: S3 as a Package Warehouse

Think of Amazon S3 like a self-storage facility:

- **create_revision_bucket()** = Renting a new storage unit. You pick a name for it, and it's yours.
- **upload_revision()** = Driving your packed box to the storage unit and placing it inside. The "key" is like the shelf label — it tells you exactly where in the unit the box sits.
- **get_revision_location()** = Writing down the address and shelf number on a card so the delivery driver (CodeDeploy) knows where to pick it up. This card is the "RevisionLocation" — a small dictionary (a structured set of key-value pairs) with the bucket name, key, and file type.
- **delete_revision_bucket()** = Clearing out the unit and canceling the rental when you're done.

### 🔍 How Does It Work?

1. **Create the bucket** — We call S3 to create a new bucket. Bucket names must be globally unique across all of AWS, so we'll use a descriptive name.
2. **Upload the zip** — We send our revision zip file to the bucket under a specific key (like a file path inside the bucket).
3. **Build the RevisionLocation** — We construct a dictionary that CodeDeploy understands: it says "this is an S3 revision, here's the bucket, here's the key, and it's a zip file."
4. **Cleanup** — When we're done with the project, we empty the bucket and delete it so we don't get charged for storage.

### 🔧 Our Game Plan

```
create_revision_bucket("my-deploy-bucket")
        ↓
upload_revision("my-deploy-bucket", "revision.zip", "revisions/v1.zip")
        ↓
get_revision_location("my-deploy-bucket", "revisions/v1.zip")
        ↓
   { revisionType: "S3", s3Location: { bucket, key, bundleType: "zip" } }
        ↓
   CodeDeploy uses this to fetch the revision during deployment
```

### 💬 Quick Check

Why do you think we need a separate `delete_revision_bucket()` function that empties the bucket first before deleting it?

**Answer:** S3 won't let you delete a bucket that still has objects inside — just like a storage facility won't accept a unit back if it still has boxes in it! The `delete_revision_bucket()` function first paginates through all objects in the bucket (there could be many revisions), deletes them all, and only then deletes the empty bucket. This two-step cleanup prevents errors and ensures we don't leave orphaned resources behind.
