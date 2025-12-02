locals {
  required_services = [
    "storage.googleapis.com",
    "iam.googleapis.com"
  ]
  suga_bucket_name = provider::corefunc::str_kebab(var.suga.name)
  bucket_name      = "${local.suga_bucket_name}-${var.suga.stack_id}"
  read_actions   = ["storage.objects.get", "storage.objects.list"]
  write_actions  = ["storage.objects.create", "storage.objects.delete"]
  delete_actions = ["storage.objects.delete"]
}

resource "google_project_service" "required_services" {
  for_each = toset(local.required_services)

  service = each.key
  project = var.project_id
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_storage_bucket" "bucket" {
  name          = local.bucket_name
  location      = var.region
  project       = var.project_id
  storage_class = var.storage_class
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  depends_on = [google_project_service.required_services]
}

resource "google_project_iam_custom_role" "bucket_access_role" {
  for_each = var.suga.services

  role_id = "BucketAccess_${substr("${var.suga.name}_${each.key}", 0, 40)}_${var.suga.stack_id}"

  project     = var.project_id
  title       = "${each.key} Bucket Access For ${var.suga.name}"
  description = "Custom role that allows access to the ${var.suga.name} bucket"
  permissions = distinct(concat(
    ["storage.buckets.list", "storage.buckets.get"], // Base roles required for finding buckets
    contains(each.value.actions, "read") ? local.read_actions : [],
    contains(each.value.actions, "write") ? local.write_actions : [],
    contains(each.value.actions, "delete") ? local.delete_actions : []
    )
  )

  depends_on = [google_project_service.required_services]
}

resource "google_project_iam_member" "iam_access" {
  for_each = var.suga.services

  project = var.project_id
  role    = google_project_iam_custom_role.bucket_access_role[each.key].name
  member  = "serviceAccount:${each.value.identities["gcp:iam:service_account"].exports["gcp_service_account:email"]}"
}
