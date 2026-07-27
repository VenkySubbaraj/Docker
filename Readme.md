# Docker MySQL Persistent Storage and Storage Expansion Lab

This lab demonstrates how to:

-   Run MySQL in a Docker container.
-   Store MySQL data outside the container's writable layer.
-   Use a Docker volume backed by a Linux filesystem.
-   Create a small filesystem for a practical storage lab.
-   Increase storage from **1 GB to 2 GB** without losing MySQL data.
-   Understand the relationship between a container, Docker volume,
    filesystem, block device, and underlying disk.
-   Relate the lab to AWS EBS storage expansion.

> **Environment:** Linux running inside WSL\
> **Important:** The WSL environment already has `/dev/sdc` mounted at
> `/var/lib/docker`. Do **not** format, resize, or otherwise modify
> `/dev/sdc` for this lab.

------------------------------------------------------------------------

## 1. Architecture

The lab creates this storage hierarchy:

``` text
Linux / WSL
│
├── /dev/sdc
│     └── /var/lib/docker       ← Existing Docker/WSL storage; DO NOT TOUCH
│
└── MySQL storage lab
      │
      └── mysql-storage.img
             │
             └── /dev/loopX
                    │
                    └── ext4 filesystem
                          │
                          └── /mnt/mysql-storage
                                  │
                                  └── Docker volume
                                          │
                                          └── MySQL container
                                              /var/lib/mysql
```

The storage expansion flow is:

``` text
1 GB disk image
      ↓
MySQL data
      ↓
Increase disk image to 2 GB
      ↓
Increase loop device size
      ↓
Expand ext4 filesystem
      ↓
Same Docker volume
      ↓
Same MySQL data
```

------------------------------------------------------------------------

# 2. Understand Docker Storage

A container has a writable layer, but that layer should not be used for
important database data.

For MySQL, persistent data should be mounted to:

``` text
/var/lib/mysql
```

The desired architecture is:

``` text
MySQL container
      │
      │ /var/lib/mysql
      ▼
Docker volume
      │
      ▼
Linux filesystem
      │
      ▼
Underlying storage
```

This gives us:

-   Data persistence across container recreation.
-   Independent management of application data.
-   The ability to expand underlying storage without recreating the
    database.

------------------------------------------------------------------------

# 3. Check the Existing WSL Storage

Before starting, inspect the current storage:

``` bash
lsblk -f
```

Example:

``` text
NAME
    FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
sda ext4   1.0
sdb swap   1           01f932d6-aa1c-4806-a750-dbef3c8b344f                [SWAP]
sdc ext4   1.0         965d387f-2656-4562-9e44-47a517695ace  915.3G     4% /var/lib/docker
                                                                           /mnt/wslg/distro
```

The important point is:

``` text
/dev/sdc → /var/lib/docker
```

This is existing WSL/Docker storage.

**Do not run `mkfs`, `resize2fs`, or other destructive filesystem
operations on `/dev/sdc`.**

For this lab, we create a separate disk image instead.

------------------------------------------------------------------------

# 4. Verify Docker and Existing Storage

Check Docker:

``` bash
docker --version
```

Check Docker service:

``` bash
sudo systemctl status docker
```

If required:

``` bash
sudo systemctl start docker
```

Check Docker's root directory:

``` bash
docker info | grep "Docker Root Dir"
```

Check Docker storage usage:

``` bash
docker system df
```

Check the filesystem:

``` bash
df -hT /var/lib/docker
```

------------------------------------------------------------------------

# 5. Create the Lab Directory

Create a directory for the storage image:

``` bash
sudo mkdir -p /opt/mysql-lab
```

------------------------------------------------------------------------

# 6. Create a 1 GB Virtual Disk Image

Create a 1 GB file:

``` bash
sudo fallocate -l 1G /opt/mysql-lab/mysql-storage.img
```

Check:

``` bash
ls -lh /opt/mysql-lab/mysql-storage.img
```

Expected:

``` text
-rw-r--r-- 1 root root 1.0G mysql-storage.img
```

At this stage, the file is just a normal file.

------------------------------------------------------------------------

# 7. Attach the Image to a Loop Device

Attach it:

``` bash
sudo losetup --find --show /opt/mysql-lab/mysql-storage.img
```

Example output:

``` text
/dev/loop0
```

The actual loop device might be different, such as `/dev/loop1`.

**Use the device returned by your system in subsequent commands.**

Check:

``` bash
lsblk
```

Expected:

``` text
NAME      SIZE TYPE
loop0       1G loop
```

For the rest of this document, `/dev/loop0` is used as an example.

------------------------------------------------------------------------

# 8. Create an ext4 Filesystem

Format the new loop device:

``` bash
sudo mkfs.ext4 /dev/loop0
```

Verify:

``` bash
lsblk -f
```

You should see:

``` text
loop0    ext4
```

### Important Safety Warning

Only format the newly created loop device.

Do **not** run:

``` bash
sudo mkfs.ext4 /dev/sdc
```

`/dev/sdc` contains your existing WSL/Docker storage.

------------------------------------------------------------------------

# 9. Mount the Filesystem

Create a mount point:

``` bash
sudo mkdir -p /mnt/mysql-storage
```

Mount the filesystem:

``` bash
sudo mount /dev/loop0 /mnt/mysql-storage
```

Check:

``` bash
df -hT /mnt/mysql-storage
```

Expected:

``` text
Filesystem     Type  Size  Used Avail Use%
/dev/loop0     ext4  ~1G   ...  ...   ...
```

The storage hierarchy is now:

``` text
/dev/loop0
    ↓
ext4 filesystem
    ↓
/mnt/mysql-storage
```

------------------------------------------------------------------------

# 10. Create a Docker Volume Backed by the Filesystem

Create the Docker volume:

``` bash
sudo docker volume create \
  --driver local \
  --opt type=none \
  --opt device=/mnt/mysql-storage \
  --opt o=bind \
  mysql_data
```

Check:

``` bash
docker volume ls
```

Expected:

``` text
DRIVER    VOLUME NAME
local     mysql_data
```

Inspect it:

``` bash
docker volume inspect mysql_data
```

The volume is backed by:

``` text
/mnt/mysql-storage
```

------------------------------------------------------------------------

# 11. Start the MySQL Container

Run MySQL:

``` bash
docker run -d \
  --name mysql-demo \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=demo_db \
  -e MYSQL_USER=demo_user \
  -e MYSQL_PASSWORD=demopass \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.4
```

Check:

``` bash
docker ps
```

Check the MySQL logs:

``` bash
docker logs mysql-demo
```

Wait until MySQL reports that it is ready for connections.

------------------------------------------------------------------------

# 12. Create Sample MySQL Data

Connect to MySQL:

``` bash
docker exec -it mysql-demo mysql -u root -p
```

Password:

``` text
rootpass
```

Create a table:

``` sql
USE demo_db;

CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    department VARCHAR(100),
    salary DECIMAL(10,2)
);
```

Insert sample data:

``` sql
INSERT INTO employees (name, department, salary)
VALUES
('Arun', 'DevOps', 75000),
('Kumar', 'Cloud', 85000),
('Priya', 'Data Engineering', 90000),
('Rahul', 'Platform Engineering', 95000),
('Suresh', 'SRE', 95000);
```

Verify:

``` sql
SELECT * FROM employees;
```

Expected data:

``` text
+----+--------+----------------------+----------+
| id | name   | department           | salary   |
+----+--------+----------------------+----------+
|  1 | Arun   | DevOps               | 75000.00 |
|  2 | Kumar  | Cloud                | 85000.00 |
|  3 | Priya  | Data Engineering     | 90000.00 |
|  4 | Rahul  | Platform Engineering | 95000.00 |
|  5 | Suresh | SRE                  | 95000.00 |
+----+--------+----------------------+----------+
```

Exit:

``` sql
exit;
```

------------------------------------------------------------------------

# 13. Verify Where MySQL Data Is Stored

Check the storage:

``` bash
sudo du -sh /mnt/mysql-storage
```

List the files:

``` bash
sudo ls -lah /mnt/mysql-storage
```

You should see MySQL-related directories such as:

``` text
demo_db
mysql
performance_schema
sys
```

The complete storage path is:

``` text
MySQL
  │
  │ /var/lib/mysql
  ▼
Docker volume: mysql_data
  │
  ▼
/mnt/mysql-storage
  │
  ▼
/dev/loop0
  │
  ▼
mysql-storage.img
```

------------------------------------------------------------------------

# 14. Test Container Persistence

Stop and remove the container:

``` bash
docker rm -f mysql-demo
```

Check:

``` bash
docker ps
```

The container is gone.

But the Docker volume should still exist:

``` bash
docker volume ls
```

Expected:

``` text
local     mysql_data
```

Now recreate the container using the same volume:

``` bash
docker run -d \
  --name mysql-demo \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=demo_db \
  -e MYSQL_USER=demo_user \
  -e MYSQL_PASSWORD=demopass \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.4
```

Connect:

``` bash
docker exec -it mysql-demo mysql -u root -p
```

Then:

``` sql
USE demo_db;

SELECT * FROM employees;
```

The five records should still exist.

This demonstrates:

``` text
Container deleted
       ↓
Docker volume remains
       ↓
MySQL data remains
```

------------------------------------------------------------------------

# 15. Check Current Storage Size

Check:

``` bash
df -hT /mnt/mysql-storage
```

Also check the disk image:

``` bash
ls -lh /opt/mysql-lab/mysql-storage.img
```

At this point:

``` text
Disk image       ≈ 1 GB
Filesystem       ≈ 1 GB
Docker volume    mysql_data
MySQL            /var/lib/mysql
```

------------------------------------------------------------------------

# 16. Stop MySQL Before Resizing

Stop the container:

``` bash
docker stop mysql-demo
```

------------------------------------------------------------------------

# 17. Unmount the Filesystem

Unmount:

``` bash
sudo umount /mnt/mysql-storage
```

Verify:

``` bash
findmnt /mnt/mysql-storage
```

It should return no mounted filesystem.

------------------------------------------------------------------------

# 18. Increase the Disk Image from 1 GB to 2 GB

Initially:

``` text
mysql-storage.img = 1 GB
```

Increase it:

``` bash
sudo truncate -s 2G /opt/mysql-lab/mysql-storage.img
```

Verify:

``` bash
ls -lh /opt/mysql-lab/mysql-storage.img
```

Expected:

``` text
2.0G mysql-storage.img
```

### Important

At this point:

``` text
Disk image      = 2 GB
Filesystem      = 1 GB
```

Increasing the disk image does **not** automatically increase the
filesystem.

------------------------------------------------------------------------

# 19. Tell the Loop Device About the New Size

Run:

``` bash
sudo losetup -c /dev/loop0
```

Check:

``` bash
lsblk
```

The loop device should now show approximately:

``` text
loop0    2G
```

If needed, inspect loop devices:

``` bash
sudo losetup -l
```

------------------------------------------------------------------------

# 20. Expand the ext4 Filesystem

Resize the ext4 filesystem:

``` bash
sudo resize2fs /dev/loop0
```

Optional filesystem check:

``` bash
sudo e2fsck -f /dev/loop0
```

Then mount it again:

``` bash
sudo mount /dev/loop0 /mnt/mysql-storage
```

Check:

``` bash
df -hT /mnt/mysql-storage
```

The filesystem should now show approximately:

``` text
Filesystem     Type  Size
/dev/loop0     ext4  2G
```

The storage has now been expanded:

``` text
1 GB → 2 GB
```

------------------------------------------------------------------------

# 21. Start MySQL Again

Start the existing container:

``` bash
docker start mysql-demo
```

Check:

``` bash
docker ps
```

Check logs:

``` bash
docker logs mysql-demo
```

------------------------------------------------------------------------

# 22. Verify MySQL Data

Connect:

``` bash
docker exec -it mysql-demo mysql -u root -p
```

Then:

``` sql
USE demo_db;

SELECT * FROM employees;
```

The original five records should still be present.

This proves:

``` text
Storage increased
      ↓
Filesystem expanded
      ↓
Docker volume unchanged
      ↓
MySQL data preserved
```

------------------------------------------------------------------------

# 23. Verify Storage From Inside the Container

Run:

``` bash
docker exec mysql-demo df -h /var/lib/mysql
```

The MySQL data directory should now see approximately 2 GB of filesystem
capacity.

You can also verify the host:

``` bash
df -hT /mnt/mysql-storage
```

------------------------------------------------------------------------

# 24. Complete Storage Expansion Flow

The complete operation was:

``` text
Before:

mysql-storage.img
       1 GB
        │
        ▼
   /dev/loop0
        │
        ▼
   ext4 filesystem
       1 GB
        │
        ▼
/mnt/mysql-storage
        │
        ▼
 Docker volume
   mysql_data
        │
        ▼
 MySQL
```

After expansion:

``` text
mysql-storage.img
       2 GB
        │
        ▼
   /dev/loop0
       2 GB
        │
        ▼
   ext4 filesystem
       2 GB
        │
        ▼
/mnt/mysql-storage
        │
        ▼
 Docker volume
   mysql_data
        │
        ▼
 MySQL
        │
        ▼
 Existing data preserved
```

------------------------------------------------------------------------

# 25. Important Commands to Remember

The core storage expansion sequence is:

``` bash
# Stop application
docker stop mysql-demo

# Unmount filesystem
sudo umount /mnt/mysql-storage

# Increase underlying disk image
sudo truncate -s 2G /opt/mysql-lab/mysql-storage.img

# Tell loop device about new size
sudo losetup -c /dev/loop0

# Expand ext4 filesystem
sudo resize2fs /dev/loop0

# Mount filesystem
sudo mount /dev/loop0 /mnt/mysql-storage

# Start application
docker start mysql-demo
```

Verification:

``` bash
df -hT /mnt/mysql-storage

docker exec mysql-demo df -h /var/lib/mysql

docker exec -it mysql-demo mysql -u root -p
```

------------------------------------------------------------------------

# 26. Storage Layers to Remember

As a DevOps engineer, remember these layers:

``` text
┌──────────────────────────────┐
│       MySQL Container        │
│                              │
│       /var/lib/mysql         │
└──────────────┬───────────────┘
               │
               │ Docker mount
               ▼
┌──────────────────────────────┐
│        Docker Volume         │
│          mysql_data          │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│       Linux Filesystem       │
│             ext4             │
│          1 GB → 2 GB         │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│        Block Device          │
│          /dev/loop0          │
│          1 GB → 2 GB         │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│        Disk Image            │
│      mysql-storage.img       │
│          1 GB → 2 GB         │
└──────────────────────────────┘
```

------------------------------------------------------------------------

# 27. How This Maps to AWS EC2 + EBS

The local lab is conceptually similar to an EC2 server using EBS:

  Local Lab              AWS
  ---------------------- ---------------------
  `mysql-storage.img`    EBS volume
  `/dev/loop0`           `/dev/nvme...`
  ext4 filesystem        ext4/XFS filesystem
  `/mnt/mysql-storage`   `/data`
  Docker volume          Docker volume
  MySQL                  MySQL

Typical AWS flow:

``` text
EBS 20 GB
   ↓
Modify EBS
   ↓
EBS 100 GB
   ↓
Expand partition if required
   ↓
Expand filesystem
   ↓
Docker sees additional capacity
   ↓
MySQL continues using the same data
```

For ext4:

``` bash
sudo resize2fs /dev/...
```

For XFS:

``` bash
sudo xfs_growfs /mount-point
```

The exact commands depend on the disk layout and filesystem.

------------------------------------------------------------------------

# 28. Critical Safety Rules

### Never format the existing Docker filesystem

Do not run:

``` bash
sudo mkfs.ext4 /dev/sdc
```

Your `/dev/sdc` is already being used by WSL/Docker.

### Do not remove the persistent volume

Do not run:

``` bash
docker volume rm mysql_data
```

unless you intentionally want to remove the persistent storage.

### Do not recreate the filesystem during expansion

Do not run:

``` bash
sudo mkfs.ext4 /dev/loop0
```

after you have already populated it with MySQL data.

Formatting would destroy the filesystem and its data.

### Expand, don't recreate

The correct approach is:

``` text
Increase underlying storage
        ↓
Increase block device visibility
        ↓
Expand filesystem
        ↓
Keep same mount
        ↓
Keep same Docker volume
        ↓
Keep same database
```

------------------------------------------------------------------------

# 29. Key Takeaways

1.  **Containers are ephemeral.** Do not depend on the container's
    writable layer for database persistence.

2.  **Docker volumes provide persistence.**

3.  A Docker volume does not necessarily represent a fixed-size disk.

4.  The usable capacity ultimately comes from the underlying
    filesystem/storage.

5.  Increasing the underlying disk does not automatically increase the
    filesystem.

6.  After increasing the disk, the filesystem must also be expanded.

7.  For ext4:

``` bash
resize2fs
```

8.  For XFS:

``` bash
xfs_growfs
```

9.  MySQL can continue using the same persistent volume after storage
    expansion.

10. The production concept is:

``` text
Disk
 ↓
Partition / LVM
 ↓
Filesystem
 ↓
Docker Volume
 ↓
Container
 ↓
Application
```

------------------------------------------------------------------------

# 30. Recommended Next Lab

After completing this exercise, the next useful exercise is **Docker +
LVM + MySQL**:

``` text
Physical Disk
      ↓
Physical Volume (PV)
      ↓
Volume Group (VG)
      ↓
Logical Volume (LV)
      ↓
ext4/XFS
      ↓
Docker Volume
      ↓
MySQL
```

Then practice:

``` bash
lvextend
    ↓
resize2fs / xfs_growfs
    ↓
Docker automatically sees additional capacity
    ↓
MySQL data remains intact
```

This is closer to storage administration you may encounter on Linux
servers and AWS EC2.
