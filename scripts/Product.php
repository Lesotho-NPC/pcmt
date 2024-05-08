<?php
namespace Akeneo\Pim\Enrichment\Component\Product\Model;


use Akeneo\Pim\Enrichment\Component\Product\Model\AbstractProduct;
use Akeneo\Pim\Enrichment\Component\Product\Model\ProductInterface;
use Ramsey\Uuid\Uuid;

/**
 * Product. An entity with flexible values, completeness, categories, associations and much more...
 *
 * @author    Nicolas Dupont <nicolas@akeneo.com>
 * @copyright 2013 Akeneo SAS (http://www.akeneo.com)
 * @license   http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */
 class Product extends AbstractProduct implements ProductInterface
{

    public string $inventory_item_uuid;

    public function __construct(?string $inventory_item_uuid = null)
    {
        parent::__construct();
        $this->inventory_item_uuid = $inventory_item_uuid ? Uuid::fromString($inventory_item_uuid) : Uuid::uuid4();
    }

    public function getInventoryItemUuid()
    {
        return $this->inventory_item_uuid;
    }


    public function setInventoryItemUuid($inventory_item_uuid)
    {
        $this->inventory_item_uuid = $inventory_item_uuid;

        return $this;
    }
    
  
}
