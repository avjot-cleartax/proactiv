cleartax_triggering_ref=$1

function die()
{
    echo "------ ERROR merge_cleartax_to_taxcloud.sh -----"
    echo $*
    echo $* > "$error_log_file"
    echo "------ ERROR merge_cleartax_to_taxcloud.sh -----"
    echo "press enter to exit"
    exit 1
}

function die_and_delete_temporary()
{
    echo "------ ERROR merge_cleartax_to_taxcloud.sh -----"
    echo $*
    echo $* > "$error_log_file"
    echo "------ ERROR merge_cleartax_to_taxcloud.sh -----"
    echo "press enter to exit"
    
    #Delete the temporary branch
    git reset --hard HEAD
    git checkout $taxcloud_default_branch || "Failed to go to branch $taxcloud_repo/$taxcloud_default_branch"
    git branch -D $temporary_branch || "Failed to delete branch $taxcloud_repo/$temporary_branch"
	cd $cleartax_repo || "Failed to go to $cleartax_repo"
	git checkout $cleartax_default_branch
	git branch -D $temporary_branch || "Failed to delete branch $cleartax_repo/$temporary_branch"
    exit 1
}

base_production_code_dir="/c/users/avjot singh/proactiv/code"
error_log_file="/c/users/avjot singh/proactiv/code/errorlogs/proactive_conflict_check_error.log"

cleartax_repo="cleartax-dev"
taxcloud_repo="taxcloud-dev"

cleartax_default_branch="shipping"
taxcloud_default_branch="taxcloud"
temporary_branch="temporary_branch/$cleartax_triggering_ref"

echo "----------" $temporary_branch "----------"
echo "----------" $cleartax_triggering_ref "----------"

#remove any existing error log file
rm "$error_log_file" || die "Failed to delete error log file"

cd "$base_production_code_dir" || die "Failed to go to directory $base_production_code_dir"

#Get the latest code for cleartax
cd $cleartax_repo || die "Failed to go to $cleartax_repo"
#revert any unstaged changes.
git reset --hard HEAD || die "Failed to revert any unstaged changes in $cleartax_repo"
git checkout $cleartax_default_branch || "Failed to go to $cleartax_default_branch" 
git reset --hard HEAD || die "Failed to revert any unstaged changes in $cleartax_repo"
git fetch https://github.com/avjot-cleartax/cleartax-dev.git
if [ `git branch --list $temporary_branch` ]; then 
    git branch -D $temporary_branch ||"Failed to delete $cleartax_repo/$temporary_branch"
fi
git checkout -b $temporary_branch $cleartax_triggering_ref || "Failed to create temporary branch"
cd -


#Get the latest code for taxcloud
cd $taxcloud_repo || die "Failed to go to $taxcloud_repo"
git reset --hard HEAD || die "Failed to revert any unstaged changes in $taxcloud_repo"
git checkout $taxcloud_default_branch || die "Failed to go to branch $taxcloud_repo/$taxcloud_default_branch"
git reset --hard HEAD || die "Failed to revert any unstaged changes in $taxcloud_repo"
git pull https://github.com/avjot-cleartax/taxcloud-dev.git $taxcloud_default_branch || die "Failed to pull the the latest code for $taxcloud_repo/$taxcloud_default_branch"
if [ `git branch --list $temporary_branch` ]
then 
    git branch -D $temporary_branch ||"Failed to delete $cleartax_repo/$temporary_branch"
fi
git checkout -b $temporary_branch

#Merge the code of cleartax_triggering_ref into this branch
git pull ../$cleartax_repo $temporary_branch --no-edit --log=10 || die_and_delete_temporary "The PR will cause conflicts with Taxcloud."

#Delete the temporary branches
git checkout $taxcloud_default_branch || "Failed to go to branch $taxcloud_repo/$taxcloud_default_branch"
git branch -D $temporary_branch || "Failed to delete branch $taxcloud_repo/$temporary_branch"
cd -
cd $cleartax_repo || "Failed to go to $cleartax_repo"
git checkout $cleartax_default_branch
git branch -D $temporary_branch || "Failed to delete branch $cleartax_repo/$temporary_branch"
echo "The PR won't cause any conflicts with Taxcloud."