<?php


use Behat\Behat\Context\Context;
use Behat\Mink\Driver\Selenium2Driver;
use Behat\Mink\Exception\ExpectationException;
use Behat\MinkExtension\Context\MinkContext;
use Behat\Testwork\Counter\Exception\TimerException;
use Doctrine\Persistence\ObjectManager;
#use Exception;
use Symfony\Component\DependencyInjection\ContainerInterface;
use GuzzleHttp\Client;
use function PHPUnit\Framework\assertArrayHasKey;
use function PHPUnit\Framework\assertContains;
use function PHPUnit\Framework\assertEquals;
use function PHPUnit\Framework\throwException;

use Context\Spin\SpinCapableTrait;




/**
 * Main feature context
 *
 * @author    Gildas Quéméner <gildas@akeneo.com>
 * @copyright 2013 Akeneo SAS (http://www.akeneo.com)
 * @license   http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */
class FeatureContext extends MinkContext implements Context
{


    /** @var string[] */
    protected static $errorMessages = [];
    protected static int $timeout;
    protected array $contexts = [];
    private  $kernel;
    private $client;
    private $response;


    public function __construct($kernel)
    {
        $this->setTimeout(['timeout' => 25000]);
        $this->kernel = $kernel;
        $this->client = new Client([
            'base_uri' => 'http://httpd', // Ensure this is the correct base URL
        ]);
    }

    public function getContainer(): ContainerInterface
    {
        return $this->kernel->getContainer()->get('test.service_container');
    }


    public function getEntityManager(): ObjectManager
    {
        return $this->getContainer()->get('doctrine')->getManager();
    }

    /**
     * @return mixed
     * @throws \Exception
     */
    public function getSubcontext(string $context)
    {
        if (!isset($this->contexts[$context])) {
            throw new \Exception(sprintf('The context %s does not exist', $context));
        }

        return $this->contexts[$context];
    }


    public static function getTimeout(): int
    {
        return static::$timeout;
    }

    public function listToArray(string $list): array
    {
        if (empty($list)) {
            return [];
        }

        return explode(', ', str_replace(' and ', ', ', $list));
    }

    public function createExpectationException(string $message): ExpectationException
    {
        return new ExpectationException($message, $this->getSession());
    }

    public function addErrorMessage(string $message)
    {
        self::$errorMessages[] = $message;
    }

    public static function getErrorMessages(): array
    {
        return self::$errorMessages;
    }

    /**
     * @throws TimerException If timeout is reached
     */
    public function wait(?string $condition = null)
    {
        if (!($this->getSession()->getDriver() instanceof Selenium2Driver)) {
            return;
        }

        $timeout = $this->getTimeout();

        $start = microtime(true);
        $end = $start + $timeout / 1000.0;

        if ($condition === null) {
            $defaultCondition = true;
            $conditions = [
                "document.readyState == 'complete'",
                // Page is ready
                "typeof $ != 'undefined'",
                // jQuery is loaded
                "!$.active",
                // No ajax request is active
                "$('#page').css('display') != 'none'",
                // Page is displayed (no progress bar)
                // Page is not loading (no black mask loading page)
                "($('.hash-loading-mask .loading-mask').length == 0 || $('.hash-loading-mask .loading-mask').css('display') == 'none')",
                "$('.jstree-loading').length == 0",
                // Jstree has finished loading
            ];

            $condition = implode(' && ', $conditions);
        } else {
            $conditions = [];
            $defaultCondition = false;
        }
        // Make sure the AJAX calls are fired up before checking the condition
        $this->getSession()->wait(100);

        $this->getSession()->wait($timeout, $condition);

        // Check if we reached the timeout unless the condition is false to explicitly wait the specified time
        if ($condition !== false && microtime(true) > $end) {
            $this->getSubcontext('hook')->collectErrors();

            if ($defaultCondition) {
                foreach ($conditions as $condition) {
                    $result = $this->getSession()->evaluateScript($condition);
                    if (!$result) {
                        throw new TimerException(
                            sprintf(
                                'Timeout of %d reached when checking on "%s"',
                                $timeout,
                                $condition
                            )
                        );
                    }
                }
            } else {
                throw new TimerException(sprintf('Timeout of %d reached when checking on %s', $timeout, $condition));
            }
        }
    }



    protected function setTimeout(array $parameters): void
    {
        static::$timeout = $parameters['timeout'];
    }


    public function spin($callback, $message, $timeout = 30)
    {
        $endTime = time() + $timeout;
        $exception = null;

        while (time() < $endTime) {
            try {
                $result = $callback();
                if ($result) {
                    return $result;
                }
            } catch (\Exception $e) {
                $exception = $e;
            }

            usleep(500000); // Sleep for 0.5 seconds
        }

        throw new \Exception($message, 0, $exception);
    }


    /**
     * @Given I am a user without access to the FHIR server
     */
    public function iAmAUserWithoutAccessToTheFhirServer()
    {
    }

    /**
     * @When I send a GET request to :arg1
     */
    public function iSendAGetRequestTo($arg1)
    {
        try {
            $this->response = $this->client->request('GET', $arg1);
        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $this->response = $e->getResponse();
        }
    }


    /**
     * @Then the response status code should be :arg1
     */
    public function theResponseStatusCodeShouldBe($arg1)
    {
        if ($this->response) {
            assertEquals($arg1, $this->response->getStatusCode());
        } else {
            throw new Exception('No response received');
        }
    }

    /**
     * @Given I am authenticated with valid credentials
     */
    public function iAmAuthenticatedWithValidCredentials()
    {

        $this->getSession()->visit($this->locatePath('/user/logout'));

        $this->spin(function () {
            return $this->getSession()->getPage()->find('css', '.AknLogin-title');
        }, 'Cannot open the login page');


        $this->spin(function ()  {
            $this->getSession()->getPage()->fillField('_username', 'Admin');
            $this->getSession()->getPage()->fillField('_password', 'Admin123');
            $signInButton = $this->getSession()->getPage()->find('css', '.form-signin button');
            $signInButton->press();

            return $signInButton;
        }, sprintf('Cannot log in as %s', 'Admin'));

    }


    /**
     * @Then the response should be able to access authenticated page
     */
    public function theResponseShouldBeAbleToAccessAuthenticatedPage()
    {
        $expectedTitle = "Attribute ACTIVE_INGREDIENT | Edit";
        $this->getSession()->visit($this->locatePath('/#/configuration/attribute/ACTIVE_INGREDIENT/edit'));


        $titleElement = $this->spin(function () {
            $this->getSession()->wait(100);
            
            return $this->getSession()->getPage()->find('css', 'head title');
        }, 'Cannot Find Attribute ACTIVE_INGREDIENT | Edit');

        $actualTitle = $titleElement->getText();

        assert($expectedTitle === $actualTitle, "Page title mismatch. Expected: $expectedTitle, Actual: $actualTitle");
    }


    /**
     * @Then the response should be in JSON format
     */
    public function theResponseShouldBeInJsonFormat()
    {
        $session = $this->getSession();
        $headers = $session->getResponseHeaders();
        $header = "application/json";

        assertContains(
            $header,
            $headers['content-type'],
        );
    }

}
