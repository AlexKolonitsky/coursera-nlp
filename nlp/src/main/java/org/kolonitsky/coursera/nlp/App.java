package org.kolonitsky.coursera.nlp;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;
import java.net.URISyntaxException;

/**
 * Hello world!
 *
 */
public class App {
    public static void main(String[] args) throws IOException, URISyntaxException {
        DataManager data = new DataManager();
        data.load(getFile(args[0]));

        System.out.println(data.e("hello", "O"));
        System.out.println(data.e("hello", "I-GENE"));
        System.out.println(data.e("me", "O"));
        System.out.println(data.e("Hello", "O"));

        System.out.println(data.argMaxE("hello", "O", "I-GENE"));
    }

    private static File getFile(String arg) throws URISyntaxException {
        return new File("D:\\Dropbox\\coursera-nlp\\nlp\\src\\main\\resources\\" + arg);
//        return new File(Thread.currentThread().getContextClassLoader().getResource(arg).toURI());
    }

}
