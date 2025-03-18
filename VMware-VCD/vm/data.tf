data "vcd_catalog" "catalog" {
  org  = var.catalog_org_name
  name = var.catalog_name
}
data "vcd_catalog_vapp_template" "template01" {
  org        = var.catalog_org_name
  catalog_id = data.vcd_catalog.catalog.id
  name       = var.template_name
}
